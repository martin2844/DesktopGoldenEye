# Testing

DesktopGoldenEye uses fail-fast PowerShell integration tests because its release
surface is a Windows launcher, package builder, portable updater, and native
plugin stack rather than a library with isolated unit-test coverage.

## Public, ROM-free CI

The release workflow runs these checks on Windows:

```powershell
.\scripts\package-desktopgoldeneye-windows.ps1 -Version 0.0.0.0-ci
.\scripts\test-desktopgoldeneye-package-failures.ps1 `
  -PackageRoot .\.work\package-windows\DesktopGoldenEye-Windows-x86-0.0.0.0-ci `
  -BundlePath .\.work\downloads\1964_GEPD_Edition_No_DRP.zip
.\scripts\test-desktopgoldeneye-portable-bootstrap.ps1 `
  -PackageArchive .\dist\DesktopGoldenEye-Windows-x86-0.0.0.0-ci.zip
```

These tests cover allow/deny lists, component hashes, ROM/state/save leakage,
corrupted upstream input, first portable install, unchanged-payload no-op,
update preservation, malformed payload rejection, rollback, rejected test-cache
paths, and protection of unrecognized pre-existing directories.

## Private ROM qualification

Run only with a legally obtained, unmodified US GoldenEye ROM:

```powershell
.\launcher\windows\Test-GoldenEye.Runtime.ps1 `
  -RomPath 'D:\Roms\007 - GoldenEye (USA).n64' `
  -InstallRoot "$env:LOCALAPPDATA\DesktopGoldenEye\Portable"
```

The test derives temporary z64, v64, and n64 byte-order fixtures from the private
ROM, verifies missing, wrong-size, and unsupported same-size image rejection,
exercises a ROM selected from a path containing spaces, checks renderer and input
configuration, proves changed-save snapshots and retention, checks
diagnostics/core selection, and runs the windowed cursor-capture regression.
Temporary ROM variants and launch aliases are deleted before the test returns.

The final manual gate launches the exact portable payload and confirms a
responsive `GOLDENEYE - Running` window. Never commit the ROM, saves, launcher
state, or game screenshots.
