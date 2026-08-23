# Current implementation status

Updated 2026-08-23.

## What works now

- The pinned MGB64 runtime is vendored as a squashed subtree at revision `0d1d40b4`.
- A native Windows x86-64 `ge007.exe` builds with MSYS2/MinGW64, CMake, and Ninja.
- The in-process Dear ImGui launcher renders through WebGPU on the test PC's AMD Radeon RX 7800 XT.
- The launcher accepts the user's ordinary US `.n64` ROM directly, detects its byte order, validates it, and keeps the ROM outside Git.
- The verified ROM boots Dam, initializes stage data, renders gameplay, saves to an isolated directory, and exits cleanly under the automated smoke route.
- A new Mods panel discovers directory packages, parses `manifest.toml`, validates a Lua entrypoint, rejects path traversal, and reports duplicate IDs and malformed packages.
- Mod catalog tests are ROM-free and pass as a native Windows executable.

Lua scripts are deliberately **not executed yet**. Discovery and validation landed first so the package Interface can be tested before untrusted code is embedded.

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

## Next vertical slice

1. Embed Lua 5.4 behind a `ModRuntime` Module with one isolated state per package.
2. Remove dangerous standard libraries and expose only a small host-owned `mod` Interface.
3. Add load journals so a failed package cannot leave partial registration behind.
4. Implement one semantic hook with high Leverage, initially a safe weapon-property patch.
5. Add launcher enable/disable state and a no-mod parity test.
6. Add `gemod validate` and `gemod run` using the same manifest fixtures as the runtime.

Android remains a later nice-to-have. Linux should follow once the Windows Lua vertical slice is stable because the runtime and launcher are already portable C/C++/SDL2.
