[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RomPath,
    [Parameter(Mandatory)][string]$InstallRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'GoldenEye.Runtime.psm1') -Force

$rom = Get-GoldenEyeRomInfo -RomPath $RomPath
if ($rom.CanonicalSha1 -ne 'ABE01E4AEB033B6C0836819F549C791B26CFDE83') {
    throw 'ROM verification did not return the canonical GoldenEye US hash.'
}

$required = @(
    '1964\1964.exe',
    '1964\source.tar.xz',
    '1964\plugin\GLideN64.dll',
    '1964\plugin\Mouse_Injector.dll',
    'launcher\GoldenEye.ps1',
    'launcher\GoldenEye.Runtime.psm1',
    'Play GoldenEye (Quality).cmd',
    'launcher-state.json'
)
foreach ($relativePath in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot $relativePath) -PathType Leaf)) {
        throw "Missing installed runtime file: $relativePath"
    }
}

$runtimeConfig = Get-Content -LiteralPath (Join-Path $InstallRoot '1964\1964.cfg') -Raw
@('VideoPlugin GLideN64.dll', 'InputPlugin Mouse_Injector.dll', 'GEFiringRateHack 1', 'AutoFullScreen 0') | ForEach-Object {
    if (-not $runtimeConfig.Contains($_)) { throw "1964 quality profile is missing: $_" }
}

$videoConfig = Get-Content -LiteralPath (Join-Path $InstallRoot '1964\plugin\GLideN64.ini') -Raw
@('video\verticalSync=0', 'video\multisampling=0', 'generalEmulation\enableLOD=1', 'frameBufferEmulation\aspect=2', 'textureFilter\txHiresEnable=1') | ForEach-Object {
    if (-not $videoConfig.Contains($_)) { throw "GLideN64 quality profile is missing: $_" }
}
if ($videoConfig -match '@[A-Z_]+@') { throw 'GLideN64 quality profile contains an unresolved template token.' }

Write-Host "PASS: ROM verified as $($rom.Format); quality runtime and launcher profile are complete."
