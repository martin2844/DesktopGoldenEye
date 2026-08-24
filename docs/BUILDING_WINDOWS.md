# Building DesktopGoldenEye on Windows

## Requirements

- Windows 10 or 11 on an x64 host
- Visual Studio 2022 or Build Tools 2022
- **Desktop development with C++**, MSVC v143 x86/x64 tools, and a Windows SDK
- Windows PowerShell 5.1 or newer
- Git

No ROM is needed to build or package. A legally obtained, unmodified US ROM is
used only for private gameplay qualification.

## Experimental source build

From PowerShell in the repository root:

```powershell
.\scripts\build-1964-windows.ps1 -Configuration Release
```

Output: `out\Release\DesktopGoldenEye.exe` (Win32/x86). A WSL-hosted checkout
is supported: the script stages legacy case-insensitive inputs under
`%LOCALAPPDATA%\DesktopGoldenEye\build-source` and copies the result back.

This proves the retained fork still compiles with current tools. It is not the
v0.1 release binary: the optimized VS2022 build currently faults in the legacy
TLB path after ROM startup. The v0.1 package therefore uses the exact optimized
core from the pinned official 1964GEPD bundle.

## Build the portable ZIP

```powershell
.\scripts\package-desktopgoldeneye-windows.ps1 -Version 0.1.0.0
```

The script:

1. downloads the official 1964GEPD no-Discord-RPC archive if needed;
2. verifies its pinned SHA-1 and SHA-256;
3. copies the upstream optimized core plus only the active GLideN64, Mouse
   Injector, and AziAudio stack, required
   configuration/runtime files, corresponding source, and the credited
   GoldenEye HUD cache;
4. removes all player state/saves and scans for ROM-like files;
5. writes component and binary hashes to `release-manifest.json`;
6. runs the package integrity test.

Output: `dist\DesktopGoldenEye-Windows-x86-0.1.0.0.zip`.

## Build the single portable EXE

```powershell
.\scripts\package-desktopgoldeneye-portable-exe.ps1 `
  -PackageArchive .\dist\DesktopGoldenEye-Windows-x86-0.1.0.0.zip
```

Output: `dist\DesktopGoldenEye-Windows-x86-0.1.0.0-Portable.exe`.

The wrapper uses Windows IExpress. On first run it expands the verified payload
to `%LOCALAPPDATA%\DesktopGoldenEye\Portable`; later versions replace only the
payload while preserving `launcher-state.json`, `1964\save`, and
`save-backups`. The executable is unsigned in v0.1.

## Run tests

Package integrity (ROM-free):

```powershell
.\scripts\test-desktopgoldeneye-package.ps1 `
  -PackageRoot .\.work\package-windows\DesktopGoldenEye-Windows-x86-0.1.0.0
.\scripts\test-desktopgoldeneye-package-failures.ps1 `
  -PackageRoot .\.work\package-windows\DesktopGoldenEye-Windows-x86-0.1.0.0 `
  -BundlePath .\.work\downloads\1964_GEPD_Edition_No_DRP.zip
.\scripts\test-desktopgoldeneye-portable-bootstrap.ps1 `
  -PackageArchive .\dist\DesktopGoldenEye-Windows-x86-0.1.0.0.zip
```

Installed runtime and private ROM smoke:

```powershell
.\launcher\windows\Test-GoldenEye.Runtime.ps1 `
  -RomPath 'D:\Roms\007 - GoldenEye (USA).n64' `
  -InstallRoot "$env:LOCALAPPDATA\DesktopGoldenEye\Portable"
```

The private test verifies all three byte orders from temporary derived fixtures,
unsupported-image rejection, generated graphics/input settings, changed-save
snapshots and retention, diagnostics, core selection, and the windowed cursor
capture regression. Do not commit the ROM, temporary fixtures, screenshots
containing game assets, launcher state, or saves. See [Testing](../TESTING.md).

## Release automation

`.github/workflows/release.yml` builds and validates Windows artifacts on pull
requests and manual runs. A `v*` tag also publishes the ZIP, portable EXE, and
SHA-256 checksum file to a GitHub prerelease.
