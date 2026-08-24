# Current status

Updated 2026-08-24.

## v0.1 release candidate

DesktopGoldenEye is a working Windows quality package, not a recompilation. The
release-qualified Win32 x86 1964GEPD core launches the user's ordinary
unmodified US ROM with GLideN64, Mouse Injector, and AziAudio. DesktopGoldenEye
adds the launcher, quality profiles, portable update flow, and diagnostics.

Verified locally:

- the package builder verifies and allowlists the checksum-pinned upstream core;
- z64, v64, and n64 byte orders are validated by size, header, and exact SHA-1;
- the supplied v64-order ROM boots to a responsive `GOLDENEYE - Running` window;
- Modern FPS mouse/WASD controls and quality rendering work in fullscreen and
  windowed modes;
- windowed pointer capture prevents the desktop right-click menu from breaking
  sniper aim/zoom;
- launcher settings cover display mode, resolution, quality, aspect, FOV,
  texture cache, mouse profile, focus behavior, and save backups;
- the portable ZIP is ROM-free, state-free, save-clean, and hash-consistent;
- the single EXE extracts without elevation and preserves settings/saves across
  payload updates.

## Public package policy

The release no longer republishes the entire mixed upstream bundle. It includes
only the active GPL runtime stack, corresponding source archive, required
runtime/configuration files, and the separately credited unmodified GoldenEye
HUD cache. Jabo, alternate plugins, Perfect Dark/GoldFinger caches, and unused
legacy DLLs are excluded. See [Third-party notices](../THIRD_PARTY_NOTICES.md).

## Known v0.1 limitations

- Windows 10/11 only; the runtime is a 32-bit emulator/plugin stack.
- Unsigned prerelease, so SmartScreen may warn.
- Only the unmodified US GoldenEye ROM is supported.
- No first-class mod manager or Lua API yet.
- Fullscreen alt-tab and the inherited 1964 audio/runtime behavior can still be
  fragile; use windowed/borderless mode when troubleshooting.
- Controller presets are not yet launcher-managed.
- The retained VS2022 source build compiles, but its optimized executable is not
  release-qualified: it faults in the legacy TLB path when a game starts. v0.1
  deliberately ships the proven upstream optimized core instead.

## Next slice

1. Gather public mission-by-mission reports and lock the default profile.
2. Add controller/accessibility presets and better crash diagnostics.
3. Implement launcher-managed ROM patches and structured cheat packages.
4. Design a runtime-neutral `.gemod` manifest before promising a Lua API.
5. Evaluate a separate portable quality runtime for Linux/macOS; do not market
   Wine as native support.
