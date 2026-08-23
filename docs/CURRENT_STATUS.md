# Current implementation status

Updated 2026-08-23.

## What works now

### Quality player track

- The official 1964GEPD no-Discord-RPC release is pinned by SHA-1 and SHA-256, downloaded outside Git, and installed without modification.
- The Windows launcher validates all three byte orders of the unmodified US ROM by exact raw SHA-1 instead of trusting the filename extension.
- It configures the latest bundled GLideN64 renderer at the primary display resolution, 16:9, accurate framebuffer/LOD/lighting/coverage settings, and the bundled high-resolution HUD cache.
- Mouse/WASD uses upstream Mouse Injector 2.3. The project did not implement this input path.
- The exact user ROM boots into a responsive `GOLDENEYE - Running` window and renders the intro in fullscreen and windowed modes.
- A ready-to-play command exists at `C:\Users\martin\Source\goldeneye-mod-platform\ready-to-play\GoldenEye-Quality\Play GoldenEye (Quality).cmd`.
- The source ROM is not copied. A no-space NTFS hard-link beside it works around 1964's whitespace-limited command-line parser.

### Experimental mod track

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

## Play the quality baseline on this PC

Double-click:

```text
C:\Users\martin\Source\goldeneye-mod-platform\ready-to-play\GoldenEye-Quality\Play GoldenEye (Quality).cmd
```

Press `4` if mouse injection/cursor lock is not active. Use `Ctrl+I` in windowed mode for sensitivity and bindings. See [QUALITY_BASELINE.md](QUALITY_BASELINE.md) before changing graphics settings; several expensive options worsen mouse latency.

## Reproduce the experimental mod track

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

1. Human-test Dam mouse feel, audio, and graphics on the quality profile, then test two renderer-stress missions.
2. Record a quality issue ledger and freeze the 1964GEPD profile before adding launcher polish.
3. Decide whether the next mod milestone Adapter-bridges ROM patches/cheats or moves to a native/decomp runtime with comparable rendering.
4. Resume the schema-backed weapon-property registry only after the target mod runtime is chosen.

Android remains a later nice-to-have. Linux follows only after a quality-capable cross-platform runtime is selected; 1964GEPD is Windows-only, while MGB64's portable paths remain experimental.
