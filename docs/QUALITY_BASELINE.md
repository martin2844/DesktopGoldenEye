# Quality-first Windows baseline

## Decision

The default player runtime is the source-built **1964GEPD Q Branch core** combined with the checksum-pinned upstream no-Discord-RPC plugin bundle. This is the best currently proven route for the project's immediate requirements: the player's ordinary US N64 ROM, Windows, 60 fps fixes specific to GoldenEye, mature mouse/WASD input, and a renderer with substantially better GoldenEye coverage than the experimental MGB64 port.

MGB64 remains the editable **Experimental Adapter** for the Lua mod work. It is not the default player runtime while its mouse feel, textures, fog, glass, and other rendering paths remain visibly behind the quality baseline.

```text
                         Runtime Interface
                    verify → configure → launch
                              │
              ┌───────────────┴────────────────┐
              ▼                                ▼
   1964 Q Branch Quality Adapter     MGB64 Experimental Adapter
   best game experience now          editable Lua/mod research
   ordinary US ROM                    ordinary US ROM
   Windows only                       Windows/Linux source paths
```

The shared Interface is small because it hides meaningful differences: bundle acquisition, hashes, ROM byte order, core selection, plugin selection, display profile, and per-runtime environment variables. Those differences stay inside each Adapter instead of leaking into the player launcher.

## What the launcher installs

The Windows setup Module:

1. accepts the unmodified US ROM in z64, v64, or n64 byte order;
2. checks size, N64 magic, and the exact raw SHA-1 for that byte order;
3. downloads the official `1964_GEPD_Edition_.No_DRP.zip` when it is not supplied locally;
4. verifies both release checksums before extraction;
5. retains the upstream source archive and notices included in the bundle;
6. installs a quality GLideN64 profile sized to the primary display;
7. selects `Mouse_Injector.dll`, `AziAudio.dll`, and the latest bundled `GLideN64.dll`;
8. creates a private launcher-state file containing the ROM path and display/input preferences, never ROM bytes;
9. creates a hard-link beside a ROM only when its filename or extension would misrepresent the verified byte order;
10. prefers an installed `1964-qbranch.exe`, with `1964.exe` retained as a compatibility fallback.

Pinned release evidence:

```text
release: 1964 GEPD Bundle (2023/07/03), no Discord Rich Presence asset
URL:     https://github.com/Graslu/1964GEPD/releases/download/latest/1964_GEPD_Edition_.No_DRP.zip
SHA-1:   d7c7099a41e8ae3427eae22d8f95796d9dfc44a8
SHA-256: dad8ce4cbdddcb8447ce59bf194ad0acf4c237a45a566cfff7d3a1310cce6f6e
```

The repository does not vendor or rehost this binary bundle. The installer retrieves the exact upstream asset. The Q Branch core is built from this repository; the bundle supplies plugins and optional cached HUD textures under multiple licenses. Direct upstream retrieval remains the conservative plugin/asset distribution model until the binary-component notice audit is finished. See [Third-party component inventory](../THIRD_PARTY_NOTICES.md).

## Quality profile

The default profile favors image quality while retaining easy latency escape hatches:

- latest bundled GLideN64 renderer;
- primary-monitor fullscreen resolution, 1280×720 windowed fallback;
- 16:9 presentation plus the Mouse Injector's GoldenEye FOV/aspect patch;
- framebuffer emulation, LOD, hardware lighting, pixel coverage, overscan, shader cache, and high-resolution HUD texture cache enabled;
- 60 Hz output and 1964's GoldenEye-specific 60 fps firing/timing fixes;
- V-sync off, 4x MSAA, and 16x anisotropic filtering by default;
- launcher-selectable FXAA/MSAA/off, AF level, aspect ratio, texture cache, and FPS overlay.

Native-resolution rendering supplies most of the image-quality gain. The Quality defaults are appropriate for the tested RX 7800 XT; on slower GPUs, disable anti-aliasing first, then lower anisotropic filtering. If mouse latency or tearing is objectionable, compare V-sync off/on and retest the feel rather than assuming one setting is universally correct.

The launcher exposes fullscreen, borderless fullscreen, and windowed modes; native and common resolutions; renderer quality, vertical FOV, and the input controls below. It also manages focus pause, save-backup retention, diagnostics, and a one-click quality reset. It persists the selection and reapplies it immediately before every launch so plugin dialogs cannot silently become the source of truth.

## Mouse and WASD ownership

The project did **not** write the low-level mouse/WASD injection. It comes from 1964GEPD's Mouse Injector 2.3 plugin and its game-specific GoldenEye memory hooks. The launcher now owns the player-facing profile applied to that plugin. The default **Modern FPS** profile uses:

- WASD movement;
- direct mouse camera look in both hip-fire and right-click aim;
- a centered weapon/crosshair instead of independent gun drift and edge-scrolling cursor aim;
- left mouse fire, right mouse aim;
- mouse wheel weapon change;
- `R` reload, `E` use/cancel, `Q` accept/next weapon;
- `Enter` start and `Ctrl` crouch;
- `4` toggle mouse injection/cursor lock;
- automatic mouse capture on focus, with `4` as the manual release/recapture key;
- startup pointer seeding inside the window, so right-click sniper aim/zoom is captured by the game rather than the Windows desktop.

The default is 100% mouse sensitivity with acceleration off. The launcher also offers **GoldenEye hybrid** (direct camera plus floating weapon movement) and **Classic Mouse Injector** (upstream cursor/edge-scroll aim) for comparison. The generated values remain in `1964/plugin/mouseinjector.ini`; `Ctrl+I` can inspect the upstream dialog while windowed, but the launcher profile is reapplied on the next play. Mouse feel must still receive a human play test; a process/render smoke cannot judge latency or preference.

## Local ready-to-play build

On the current PC:

```text
C:\Users\martin\Source\goldeneye-mod-platform\ready-to-play\GoldenEye-Quality\Play GoldenEye (Quality).cmd
```

Double-click that command to open the Q Branch launcher, choose display and control settings, and start the game. The original ROM remains at `D:\Roms\007 - GoldenEye (USA).n64`. Its extension says n64 but its verified byte order is v64, so setup created `D:\Roms\GoldenEye007USA.v64` as a second NTFS directory entry for the same 12 MiB file—not a copied ROM.

For setup from source:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\launcher\windows\GoldenEye.ps1 `
  -Action Setup `
  -RomPath 'D:\Roms\007 - GoldenEye (USA).n64' `
  -InstallRoot "$env:LOCALAPPDATA\GoldenEyeModPlatform"
```

For a windowed diagnostic launch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "$env:LOCALAPPDATA\GoldenEyeModPlatform\launcher\GoldenEye.ps1" `
  -Action Play -Runtime Quality `
  -InstallRoot "$env:LOCALAPPDATA\GoldenEyeModPlatform" -Windowed
```

To build and install the forked core beside that runtime, follow [Building Q Branch on Windows](BUILDING_WINDOWS.md). Setup alone remains usable because it retains the official core as fallback.

## Known limitations and next gate

- Q Branch is an emulator-based 32-bit Windows runtime, not a static native recompilation.
- It provides ROM-hack/cheat/plugin compatibility, not the in-process Lua semantic Interface built in MGB64.
- The upstream bundle is mature but old and can occasionally lock up or develop audio delay; its own guide recommends pause/resume for the latter.
- Fullscreen alt-tab is fragile. Use windowed mode while changing plugins or settings.
- Mouse Injector supports only the US GoldenEye ROM.
- Automated evidence proves hash validation, exact bundle provenance, a reproducible source build, quoted-path native launch, launcher selection of Q Branch, successful ROM boot, a responsive running game window, GLideN64 rendering, windowed input capture, settings generation, backup deduplication, diagnostics, and clean process exit. Human mission play remains required to rate mouse smoothness, audio, and visual correctness.

The next engineering gate is not more launcher UI. First play Dam and two renderer-stress missions on this exact profile, record input/audio/render defects, and freeze the quality settings. Then move mod work behind the Runtime Interface or migrate to a higher-quality native/decomp base without changing the player-facing launcher contract.
