# Changelog

All notable DesktopGoldenEye changes are documented here.

## [0.1.0.0] - 2026-08-24

### Added

- Portable Windows launcher with Modern FPS, Hybrid, and Classic control profiles.
- Fullscreen, borderless, and windowed display settings with quality renderer controls.
- Local validation for supported US GoldenEye ROM byte orders and paths containing spaces.
- Windowed mouse capture that keeps right-click sniper aim inside the game.
- Automatic save backups, diagnostics, a concurrent-session guard, active-component hashes, and a ROM-free portable EXE.
- DesktopGoldenEye branding, release documentation, issue templates, and tagged-release automation.

### Changed

- Public packages now contain only the checksum-pinned active 1964GEPD, GLideN64, Mouse Injector, and AziAudio stack plus the separately credited GoldenEye HUD cache.
- The discontinued experimental MGB64 import remains in Git history and upstream research links instead of the release tree.

### Known limitations

- The release is unsigned and Windows-only.
- First-class mod installation, controller presets, and native Linux/macOS builds are not included yet.
- The retained optimized VS2022 source build is experimental; v0.1 ships the proven upstream optimized core.
