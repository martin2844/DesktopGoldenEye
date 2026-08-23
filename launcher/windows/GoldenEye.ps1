[CmdletBinding()]
param(
    [ValidateSet('Setup', 'Play', 'Verify')][string]$Action = 'Play',
    [ValidateSet('Quality', 'Experimental')][string]$Runtime = 'Quality',
    [string]$RomPath,
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'GoldenEyeModPlatform'),
    [string]$BundlePath,
    [string]$ExperimentalExecutable,
    [switch]$Windowed,
    [switch]$Wait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'GoldenEye.Runtime.psm1') -Force

$statePath = Join-Path $InstallRoot 'launcher-state.json'
if (-not $RomPath -and (Test-Path -LiteralPath $statePath)) {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $RomPath = $state.romPath
}
if (-not $RomPath) {
    throw 'Pass -RomPath on first setup. Later launches use the private launcher-state.json file.'
}

try {
    if ($Action -eq 'Verify') {
        $rom = Get-GoldenEyeRomInfo -RomPath $RomPath
        Write-Host "Verified GoldenEye 007 US ROM: $($rom.Format), raw SHA-1 $($rom.Sha1)"
        exit 0
    }

    if ($Action -eq 'Setup') {
        $result = Install-GoldenEyeRuntime -InstallRoot $InstallRoot -RomPath $RomPath -BundlePath $BundlePath
        $state = [ordered]@{ schemaVersion = 1; romPath = $result.Rom.Path; preferredRuntime = 'Quality' }
        $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8

        $commandPath = Join-Path $InstallRoot 'Play GoldenEye (Quality).cmd'
        $command = @'
@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\launcher\GoldenEye.ps1" -Action Play -Runtime Quality -InstallRoot "."
set "goldeneye_exit=%errorlevel%"
popd
if not "%goldeneye_exit%"=="0" pause
exit /b %goldeneye_exit%
'@
        Set-Content -LiteralPath $commandPath -Value $command -Encoding ASCII
        Write-Host "Quality runtime ready: $($result.RuntimePath)"
        Write-Host "Launcher: $commandPath"
        exit 0
    }

    $process = Start-GoldenEyeRuntime -Runtime $Runtime -InstallRoot $InstallRoot -RomPath $RomPath -ExperimentalExecutable $ExperimentalExecutable -Windowed:$Windowed -Wait:$Wait
    Write-Host "Started $Runtime runtime (PID $($process.Id))."
}
catch {
    Write-Error $_
    exit 1
}
