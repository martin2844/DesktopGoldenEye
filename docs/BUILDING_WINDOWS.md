# Building Q Branch on Windows

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
out\Release\1964-qbranch.exe
```

The source predates case-sensitive Windows filesystems and contains include-name case mismatches. When invoked from a WSL UNC checkout, the script stages only build inputs under `%LOCALAPPDATA%\1964QBranch\build-source`, builds there, and copies the result back. The repository remains the source of truth.

The inherited code emits legacy compiler warnings. Warnings are visible intentionally; a successful build must end with the produced executable message and a zero exit code.

## Install beside the verified quality runtime

Pass an existing launcher install root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\build-1964-windows.ps1 `
  -Configuration Release `
  -InstallRoot "$env:LOCALAPPDATA\GoldenEyeModPlatform"
```

The script verifies the expected core and active plugins, then copies only `1964-qbranch.exe`. It never replaces `1964.exe`. The launcher automatically prefers Q Branch when present and falls back when absent.

## Verify without committing game data

After Setup, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "$env:LOCALAPPDATA\GoldenEyeModPlatform\launcher\Test-GoldenEye.Runtime.ps1" `
  -RomPath 'D:\Roms\GoldenEye007USA.v64' `
  -InstallRoot "$env:LOCALAPPDATA\GoldenEyeModPlatform"
```

The test validates ROM identity, generated graphics/input settings, save-backup deduplication, diagnostics, and windowed capture. A human mission test is still required for subjective mouse latency, audio, and visual quality.
