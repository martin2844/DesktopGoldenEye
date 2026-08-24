# Desktop release contract

## Player promise

Every supported platform artifact contains everything except copyrighted game
data. A player downloads one file, opens it, selects a legally obtained ROM,
gets a clear validation result, and presses **Play GoldenEye**. They never need
to locate an emulator, pick plugins, edit INI files, or use a terminal.

## v0.1 artifacts

| Artifact | Purpose |
|---|---|
| `DesktopGoldenEye-Windows-x86-0.1.0.0-Portable.exe` | Recommended self-extracting player |
| `DesktopGoldenEye-Windows-x86-0.1.0.0.zip` | Transparent portable directory |
| `SHA256SUMS.txt` | Download integrity verification |

Both player formats contain the same validated payload. No ROM, extracted game
assets, launcher state, or prebuilt save is present.

## Required contents

- checksum-pinned, release-qualified upstream 1964GEPD core;
- GLideN64, Mouse Injector, and AziAudio active plugins;
- required runtime/configuration data and optional credited GoldenEye HUD cache;
- launcher, defaults, saves/backups, and diagnostics;
- GPL license, notices, component manifest, active binary hashes, source
  revision, and corresponding plugin source;
- no unused legacy plugins.

## Platform matrix

| Platform | v0.1 status | Gate |
|---|---|---|
| Windows 10/11 x64 host | Supported prerelease (x86 runtime) | clean artifact, ROM smoke, checksums, notices |
| Linux x86-64 | Research | quality-equivalent renderer/input/audio and same launcher contract |
| macOS Apple Silicon | Research | native quality runtime, app bundle, save/ROM-picker contract |
| Android | Nice-to-have | only after desktop runtime and mod interfaces stabilize |

Wine may be documented as experimental but does not count as native Linux or
macOS support.

## Release gates

- clean source checkout assembles the allowlisted package on Windows;
- package tests pass and reject ROM/state/save/unused plugin files;
- private supported-ROM smoke reaches a responsive running game;
- ZIP and EXE hashes are published;
- notices and corresponding source ship beside binaries;
- release is labeled unsigned/prerelease until code signing exists.
