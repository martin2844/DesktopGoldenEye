# Current implementation status

Updated 2026-08-23.

## What works now

- The pinned MGB64 runtime is vendored as a squashed subtree at revision `0d1d40b4`.
- A native Windows x86-64 `ge007.exe` builds with MSYS2/MinGW64, CMake, and Ninja.
- The in-process Dear ImGui launcher renders through WebGPU on the test PC's AMD Radeon RX 7800 XT.
- The launcher accepts the user's ordinary US `.n64` ROM directly, detects its byte order, validates it, and keeps the ROM outside Git.
- The verified ROM boots Dam, initializes stage data, renders gameplay, saves to an isolated directory, and exits cleanly under the automated smoke route.
- A new Mods panel discovers directory packages, parses `manifest.toml`, validates a Lua entrypoint, rejects path traversal, and reports duplicate IDs and malformed packages.
- Packages are disabled by default. Checked packages persist in the local launcher profile and execute only when Play is pressed.
- Every enabled package gets an isolated Lua state with an 8 MiB allocation ceiling, a 250 ms setup budget, no filesystem/process/module/debug libraries, and an allowlisted host API.
- Loads are transactional: a missing, invalid, runaway, or failing enabled mod closes all states and restores host mutations before gameplay.
- The first semantic operation is `api.game.unlock_all_levels(true)`. The example mod uses it to unlock the solo campaign for that session, then the host restores the previous value on unload.
- Mod catalog and runtime sandbox tests are ROM-free and pass as native Windows executables.

The Lua Interface is intentionally tiny. Mods can log and toggle the semantic all-levels unlock; they cannot access files, launch processes, load native modules, or mutate arbitrary game memory.

## Reproduce it on this PC

From WSL:

```sh
cd /home/martin/goldeneye-mod-platform
./scripts/dev-windows.sh all
```

The command syncs the asset-free source to the native Windows staging tree, builds `ge007.exe`, runs the ROM-free catalog test, captures the Mods panel, performs a private Dam smoke using `GOLDENEYE_ROM_PATH` from ignored `.env`, and creates a portable zip. It never copies the ROM into the repository or release bundle.

For a normal interactive run, open the built `ge007.exe`, choose the ROM, and press Play. The launcher remembers the selection in the user's application data.

## First mod manifest contract

Development packages are directories under `mods/` with this shape:

```text
hello-agent/
├── manifest.toml
└── main.lua
```

The current v1 subset is:

```toml
manifest_version = 1
id = "example.hello-agent"
name = "Hello, Agent"
version = "0.1.0"
author = "Your Name"
description = "What the mod does."
entrypoint = "main.lua"
```

`id`, `name`, `version`, and `entrypoint` are required. The ID accepts letters, digits, `.`, `_`, and `-`. The entrypoint must be a relative `.lua` path inside the package and must exist. The parser is intentionally a documented TOML subset until the package schema stabilizes.

The entrypoint returns either `function(api)` or `{ on_load = function(api) ... end }`. Current API:

```lua
api.log("attributed message")
api.game.unlock_all_levels(true)
```

## Next vertical slice

1. Implement a schema-backed weapon-property registry and a safe PP7 damage patch.
2. Add a no-mod gameplay parity test and prove disable/unload restores baseline values.
3. Surface attributed load errors in the launcher instead of only the diagnostic log/process status.
4. Add dependency ordering, conflicts, and per-profile resolution.
5. Add `gemod validate` and `gemod run` using the same manifest fixtures as the runtime.
6. Add transactional hot reload after the immutable pre-boot registry lifecycle is stable.

Android remains a later nice-to-have. Linux should follow once the Windows Lua vertical slice is stable because the runtime and launcher are already portable C/C++/SDL2.
