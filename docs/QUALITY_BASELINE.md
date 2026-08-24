# Quality-first Windows baseline

## Runtime decision

v0.1 uses the checksum-pinned upstream 1964GEPD optimized core with GLideN64,
Mouse Injector, and AziAudio. DesktopGoldenEye supplies the launcher and tested
profiles around that stack. This is the only path tested here that combines
GoldenEye-specific 60 FPS fixes, mature mouse aiming, and consistently good
rendering. It accepts a normal user-supplied ROM directly.

The runtime is Windows-only and emulator-based. Earlier native/decomp/recomp
experiments were not good enough to replace this baseline; they are recorded in
[Recomp research](RECOMP_RESEARCH.md), not shipped in the release tree.

## Pinned upstream input

```text
release: 1964 GEPD Bundle (2023/07/03), No Discord Rich Presence
URL:     https://github.com/Graslu/1964GEPD/releases/download/latest/1964_GEPD_Edition_.No_DRP.zip
SHA-1:   d7c7099a41e8ae3427eae22d8f95796d9dfc44a8
SHA-256: dad8ce4cbdddcb8447ce59bf194ad0acf4c237a45a566cfff7d3a1310cce6f6e
```

The release builder copies only the active stack and retains the upstream
`source.tar.xz` for exact plugin source/license correspondence.

## Default presentation

- primary-monitor fullscreen resolution and 1280×720 windowed fallback;
- widescreen presentation with GoldenEye FOV/aspect correction;
- framebuffer emulation, LOD, hardware lighting, pixel coverage, overscan, and
  shader cache enabled;
- optional unmodified enhanced GoldenEye HUD texture cache;
- VSync off, 4× MSAA, and 16× anisotropic filtering;
- launcher-selectable fullscreen, borderless, windowed, FXAA/MSAA/off, AF,
  aspect, FOV, texture cache, and FPS overlay.

Disable antialiasing first on slower GPUs. Compare VSync on/off if input latency
or tearing is objectionable.

## Default input

Mouse Injector supplies the low-level GoldenEye-specific hooks; DesktopGoldenEye
supplies and reapplies the player-facing profile:

- WASD movement and direct mouse camera look;
- centered crosshair/weapon rather than edge-scroll cursor aim;
- left-click fire, right-click aim, wheel weapon change;
- `R` reload, `E` use/cancel, `Q` accept, `Ctrl` crouch;
- `4` releases/recaptures the mouse;
- automatic focus capture and window-client pointer seeding.

The last behavior is the windowed sniper regression fix: right-click stays in
the game instead of opening the Windows desktop context menu.

## Qualification evidence

Automated checks cover ROM fingerprints, quoted paths, generated configuration,
component hashes, save-backup behavior, diagnostics, package allow/deny lists,
PowerShell parsing, and windowed capture. A private ROM smoke confirms the exact
package reaches a responsive running game with GLideN64 rendering. Subjective
mouse feel, audio, and mission correctness still require human play.
