# Roadmap

## v0.1 — Windows quality prerelease

- [x] Checksum-pinned, release-qualified 1964GEPD core
- [x] Modern FPS mouse/WASD profiles
- [x] Fullscreen, borderless, windowed, and renderer settings
- [x] Windowed sniper/right-click capture fix
- [x] ROM validation, saves, backups, and diagnostics
- [x] Portable ZIP and single self-extracting EXE
- [x] Active-stack-only packaging, source, credits, and hashes
- [x] Branded repository, launcher, and portable release
- [ ] Publish and gather mission qualification reports

## v0.2 — hardening and controls

- Controller presets and rebinding UX
- Accessibility options and clearer first-run guidance
- Crash/hang/audio recovery tooling
- Automated clean-machine release qualification
- Mission/GPU compatibility matrix
- Repair and qualify the optimized VS2022 source build

## v0.3 — safe mod manager

- Launcher-managed ROM patch profiles
- Structured cheat packages
- Compatibility, conflict, update, and rollback model
- Local catalog/import UI

## v0.4 — semantic mod API experiment

- `.gemod` manifest and permissions
- Sandboxed Lua host behind a runtime-neutral interface
- Semantic weapon/objective/event APIs
- Author template, validator, packaging, and diagnostics

## Later — more desktop platforms

Evaluate native Linux and macOS runtimes against the Windows quality baseline.
Android remains a nice-to-have after the desktop runtime and mod contracts are
stable. A build that merely launches is not enough for a support claim.
