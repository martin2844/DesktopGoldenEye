# Current implementation status

Updated 2026-08-24.

## What works now

### Quality player track

- This repository is now a real fork of `Graslu/1964GEPD`, with upstream preserved as a Git remote and in the branch ancestry.
- The 1964 x86 C core builds with Visual Studio 2022 Build Tools through `scripts/build-1964-windows.ps1`, producing `out/Release/DesktopGoldenEye.exe`.
- The native command-line parser now handles quoted ROM directory and filename arguments, preserves case, bounds output, and uses the `-r` directory during direct launch.
- The official no-Discord-RPC release remains pinned by SHA-1 and SHA-256 and supplies the proven GLideN64, AziAudio, Mouse Injector, configuration, and notice files.
- The Windows launcher validates all three byte orders of the unmodified US ROM by exact raw SHA-1 instead of trusting the filename extension.
- The launcher prefers the source-built DesktopGoldenEye core and retains the legacy Q Branch/upstream executables as fallbacks.
- It configures GLideN64 for display mode/resolution, aspect ratio, V-sync, MSAA or FXAA, anisotropic filtering, FPS overlay, accurate framebuffer/LOD/lighting/coverage settings, and the bundled high-resolution HUD cache.
- Mouse/WASD uses upstream Mouse Injector 2.3. The project did not implement this input path.
- The launcher owns Modern FPS, GoldenEye hybrid, and Classic control presets; sensitivity, acceleration, invert-Y, head-roll reduction, FOV, and focus pause are configurable.
- Windowed startup centers the pointer inside the client before Mouse Injector captures it, preventing right-click sniper zoom from opening the desktop context menu.
- Save files receive content-aware rolling backups with SHA-256 manifests, and the launcher can copy privacy-conscious diagnostics including selected-core/plugin hashes and ROM verification status.
- The exact user ROM boots into a responsive `GOLDENEYE - Running` window and renders the intro in fullscreen and windowed modes.
- A ROM-free all-in-one archive builder creates `dist\DesktopGoldenEye-Windows-x86-<version>.zip`; its root `DesktopGoldenEye.cmd` is the transparent portable-folder entry point.
- A second builder wraps that validated ZIP as one `DesktopGoldenEye-...-Portable.exe`. First launch extracts to the user's local application data without elevation; cached launches reuse the payload and preserve saves/settings across updates.
- The source ROM is not copied. A byte-order-correct NTFS hard-link supplies the correct `.v64` extension because the user's file is named `.n64` despite containing v64 byte order.

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
C:\Users\martin\Source\DesktopGoldenEye\DesktopGoldenEye.cmd
```

Press `4` if mouse injection/cursor lock is not active. The launcher is the source of truth for normal controls and graphics; `Ctrl+I` remains available in windowed mode for inspecting the upstream plugin dialog.

## Rebuild and package DesktopGoldenEye

From Windows PowerShell in the checkout:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\build-1964-windows.ps1 `
  -Configuration Release `
  -InstallRoot 'C:\Users\martin\Source\DesktopGoldenEye'
```

The script locates Visual Studio 2022 MSBuild, stages WSL checkouts onto a case-insensitive NTFS path when necessary, builds the Win32 core, and installs it as `DesktopGoldenEye.exe` without overwriting `1964.exe`. `scripts/package-desktopgoldeneye-windows.ps1` produces the complete ROM-free player ZIP; `scripts/package-desktopgoldeneye-portable-exe.ps1` turns the validated ZIP into one player-facing EXE.

## Reproduce the experimental mod track

From WSL:

```sh
cd /home/martin/DesktopGoldenEye
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

1. Human-test Dam plus two renderer-stress missions with the DesktopGoldenEye quality presets and record remaining input/audio/render defects.
2. Add a clean-machine packaging job with a complete plugin/asset license inventory and checksummed artifacts.
3. Move the Mouse Injector source into a reproducible plugin build, then add controller and accessibility presets.
4. Choose the first mod bridge: structured cheats/ROM patches in 1964GEPD, or a semantic API hosted by a quality-equivalent native runtime.

Android remains a later nice-to-have. Linux follows only after a quality-capable cross-platform runtime is selected; 1964GEPD is Windows-only, while MGB64's portable paths remain experimental.
