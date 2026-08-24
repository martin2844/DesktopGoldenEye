[CmdletBinding()]
param([Parameter(Mandatory)][string]$PackageRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $PackageRoot).Path

$required = @(
    'DesktopGoldenEye.cmd',
    'README-FIRST.txt',
    'release-manifest.json',
    'LICENSE',
    'NOTICE.md',
    'THIRD_PARTY_NOTICES.md',
    'launcher\GoldenEye.ps1',
    'launcher\GoldenEye.Launcher.ps1',
    'launcher\GoldenEye.Runtime.psm1',
    '1964\1964.exe',
    '1964\source.tar.xz',
    '1964\zlib.dll',
    '1964\msvcr100.dll',
    '1964\plugin\mouseinjector.ini',
    '1964\plugin\GLideN64.dll',
    '1964\plugin\Mouse_Injector.dll',
    '1964\plugin\AziAudio.dll',
    '1964\plugin\cache\credits.txt',
    '1964\plugin\cache\GOLDENEYE_HIRESTEXTURES.dat',
    '1964\plugin\cache\GOLDENEYE_HIRESTEXTURES.htc'
)
foreach ($relativePath in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf)) {
        throw "Package is missing required file: $relativePath"
    }
}
if (Test-Path -LiteralPath (Join-Path $root 'launcher-state.json')) {
    throw 'Package contains player-specific launcher state.'
}
$saveFiles = @(Get-ChildItem -LiteralPath (Join-Path $root '1964\save') -File -ErrorAction SilentlyContinue)
if ($saveFiles.Count -ne 0) { throw "Package contains a prebuilt save: $($saveFiles[0].Name)" }
$forbiddenRuntimeFiles = @(
    '1964\DesktopGoldenEye.exe',
    '1964\plugin\Jabo_Direct3D6.dll',
    '1964\plugin\Jabo_Direct3D8.dll',
    '1964\plugin\GLN64old.dll',
    '1964\plugin\GLN64_2020.dll',
    '1964\plugin\Glide64.dll',
    '1964\plugin\NRage_Input_V2.dll',
    '1964\plugin\Mouse_Injector_Speedrun.dll',
    '1964\plugin\cache\Perfect Dark_HIRESTEXTURES.htc',
    '1964\plugin\cache\GOLDFINGER_HIRESTEXTURES.htc'
)
foreach ($relativePath in $forbiddenRuntimeFiles) {
    if (Test-Path -LiteralPath (Join-Path $root $relativePath)) {
        throw "Public package contains an unused or out-of-scope runtime file: $relativePath"
    }
}
$romFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.Extension -in @('.z64', '.v64', '.n64', '.rom') })
if ($romFiles.Count -ne 0) { throw "Package contains a ROM-like file: $($romFiles[0].FullName)" }

$manifest = Get-Content -LiteralPath (Join-Path $root 'release-manifest.json') -Raw | ConvertFrom-Json
if ($manifest.product -ne 'DesktopGoldenEye' -or $manifest.romIncluded -ne $false) {
    throw 'Release manifest product or ROM declaration is invalid.'
}
if ($manifest.components.Count -lt 5) { throw 'Release manifest component inventory is incomplete.' }
foreach ($property in $manifest.activeFiles.psobject.Properties) {
    $path = Join-Path $root $property.Name
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $property.Value) { throw "Manifest hash mismatch: $($property.Name)" }
}

$parseErrors = $null
foreach ($relativePath in @('launcher\GoldenEye.ps1', 'launcher\GoldenEye.Launcher.ps1', 'launcher\GoldenEye.Runtime.psm1')) {
    $scriptText = Get-Content -LiteralPath (Join-Path $root $relativePath) -Raw
    [void][System.Management.Automation.Language.Parser]::ParseInput($scriptText, [ref]$null, [ref]$parseErrors)
    if ($parseErrors.Count -ne 0) { throw "PowerShell parse failure in $relativePath`: $($parseErrors[0].Message)" }
}

Write-Host 'PASS: DesktopGoldenEye package is complete, ROM-free, state-free, save-clean, and hash-consistent.'
