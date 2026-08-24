# Building DesktopGoldenEye on Windows

## Requirements

- Windows 10 or 11, x64
- Visual Studio 2022 Build Tools or Visual Studio 2022
- The **Desktop development with C++** workload, MSVC v143 x86/x64 tools, and a Windows 10/11 SDK
- PowerShell 5.1 or newer
- A checkout of this repository; WSL-hosted checkouts are supported

No ROM is needed to compile. A legally obtained, unmodified US GoldenEye ROM is needed only for the private gameplay smoke test.

## Build

From PowerShell in the repository:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\build-1964-windows.ps1 `
  -Configuration Release
```

Output:

```text
out\Release\DesktopGoldenEye.exe
```

The source predates case-sensitive Windows filesystems and contains include-name case mismatches. When invoked from a WSL UNC checkout, the script stages only build inputs under `%LOCALAPPDATA%\DesktopGoldenEye\build-source`, builds there, and copies the result back. The repository remains the source of truth.

The inherited code emits legacy compiler warnings. Warnings are visible intentionally; a successful build must end with the produced executable message and a zero exit code.

## Install beside the verified quality runtime

Pass an existing launcher install root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\build-1964-windows.ps1 `
  -Configuration Release `
  -InstallRoot "$env:LOCALAPPDATA\DesktopGoldenEye"
```

The script verifies the expected core and active plugins, then copies only `DesktopGoldenEye.exe`. It never replaces `1964.exe`. The launcher automatically prefers the DesktopGoldenEye core when present and retains the old Q Branch and upstream filenames as migration fallbacks.

## Build the all-in-one player archive

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\package-desktopgoldeneye-windows.ps1 `
  -Version 0.1.0
```

This builds the core, downloads and checksum-verifies the upstream runtime when needed, and produces:

```text
dist\DesktopGoldenEye-Windows-x86-0.1.0.zip
```

The archive contains the core, graphics/audio/input plugins, launcher, quality profiles, notices, source pointer, and a release manifest with hashes. It contains no ROM. The player extracts it, runs `DesktopGoldenEye.cmd`, selects their ROM, and presses Play.

## Verify without committing game data

After Setup, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "$env:LOCALAPPDATA\DesktopGoldenEye\launcher\Test-GoldenEye.Runtime.ps1" `
  -RomPath 'D:\Roms\GoldenEye007USA.v64' `
  -InstallRoot "$env:LOCALAPPDATA\DesktopGoldenEye"
```

The test validates ROM identity, generated graphics/input settings, save-backup deduplication, diagnostics, and windowed capture. A human mission test is still required for subjective mouse latency, audio, and visual quality.
