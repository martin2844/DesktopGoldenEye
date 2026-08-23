[CmdletBinding()]
param(
    [ValidateSet('Setup', 'Launcher', 'Play', 'Verify')][string]$Action = 'Launcher',
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

$settings = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -RomPath $RomPath
$RomPath = $settings.romPath
if (-not $RomPath -and $Action -ne 'Launcher') {
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

        $commandPath = Join-Path $InstallRoot 'Play GoldenEye (Quality).cmd'
        $command = @'
@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\launcher\GoldenEye.ps1" -Action Launcher -Runtime Quality -InstallRoot "."
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

    if ($Action -eq 'Launcher') {
        & (Join-Path $PSScriptRoot 'GoldenEye.Launcher.ps1') -InstallRoot $InstallRoot
        exit 0
    }

    $process = Start-GoldenEyeRuntime -Runtime $Runtime -InstallRoot $InstallRoot -RomPath $RomPath -ExperimentalExecutable $ExperimentalExecutable -Settings $settings -Windowed:$Windowed -Wait:$Wait
    Write-Host "Started $Runtime runtime (PID $($process.Id))."
}
catch {
    Write-Error $_
    exit 1
}
