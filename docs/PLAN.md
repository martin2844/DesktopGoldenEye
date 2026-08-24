# DesktopGoldenEye plan

## Product goal

Deliver the easiest high-quality way to play a legally owned US GoldenEye 007
ROM on desktop machines, then layer approachable mods onto a stable runtime
contract. Windows quality comes first; platform claims follow evidence.

## Phase 1 — v0.1 Windows foundation

- pin and allowlist the proven 1964GEPD quality core;
- retain a modern source-build path without shipping it before runtime qualification;
- ship modern mouse/WASD controls and display/quality options;
- validate the ROM locally and never copy it into releases;
- preserve saves/settings across portable-EXE updates;
- publish an allowlisted runtime package with exact credits/source/checksums;
- automate Windows release builds.

Exit: a clean v0.1 ZIP and portable EXE pass integrity checks and a private ROM
smoke, then publish as an unsigned GitHub prerelease.

## Phase 2 — player hardening

- mission qualification matrix and reproducible issue reports;
- controller and accessibility presets;
- crash/hang recovery, better audio troubleshooting, and diagnostics export;
- signed artifacts when sustainable;
- clean-machine and lower-end-GPU coverage.

Exit: common campaign play is reliable enough to remove the prerelease label.

## Phase 3 — low-risk mod packages

- launcher-managed BPS/xdelta/IPS patch profiles that never redistribute ROMs;
- structured 1964 cheats with metadata and compatibility declarations;
- enable/disable order, conflicts, checksums, and safe rollback;
- community catalog format without an executable-code supply-chain risk.

Exit: install, disable, update, and remove a mod without editing game files or
losing saves.

## Phase 4 — semantic scripting

- freeze a `.gemod` manifest and permission model;
- expose semantic GoldenEye concepts, not raw RDRAM offsets;
- isolate script states, bound time/memory, and attribute errors;
- define save migration, dependencies, conflicts, and reproducible packaging;
- prove one useful end-to-end mod through the public API.

Exit: a new author can edit Lua, relaunch, see an attributed result, and package
one portable mod without rebuilding DesktopGoldenEye.

## Phase 5 — portable runtime evaluation

- score active open-source native/decomp/recomp candidates against v0.1 image,
  input, audio, save, and mission quality;
- require ordinary-ROM import and a maintainable license/provenance story;
- keep the launcher and mod contracts runtime-neutral;
- add native Linux, macOS, then Android only after each meets the same gate.

Exit: platform support means quality parity, not merely compiling.
