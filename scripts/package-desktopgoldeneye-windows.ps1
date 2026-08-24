[CmdletBinding()]
param(
    [string]$Version = '0.1.0-dev',
    [string]$BundlePath,
    [string]$OutputDirectory,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $repositoryRoot 'dist' }
$release = [ordered]@{
    url = 'https://github.com/Graslu/1964GEPD/releases/download/latest/1964_GEPD_Edition_.No_DRP.zip'
    sha1 = 'D7C7099A41E8AE3427EAE22D8F95796D9DFC44A8'
    sha256 = 'DAD8CE4CBDDDCB8447CE59BF194AD0ACF4C237A45A566CFFF7D3A1310CCE6F6E'
}

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot 'build-1964-windows.ps1') -Configuration Release
}
$core = Join-Path $repositoryRoot 'out\Release\DesktopGoldenEye.exe'
if (-not (Test-Path -LiteralPath $core -PathType Leaf)) {
    throw "DesktopGoldenEye core was not found at '$core'. Build it first or omit -SkipBuild."
}

if (-not $BundlePath) {
    $downloads = Join-Path $repositoryRoot '.work\downloads'
    New-Item -ItemType Directory -Path $downloads -Force | Out-Null
    $BundlePath = Join-Path $downloads '1964_GEPD_Edition_No_DRP.zip'
}
if (-not (Test-Path -LiteralPath $BundlePath -PathType Leaf)) {
    Write-Host 'Downloading the checksum-pinned 1964GEPD runtime bundle...'
    Invoke-WebRequest -UseBasicParsing -Uri $release.url -OutFile $BundlePath
}
$bundleSha1 = (Get-FileHash -LiteralPath $BundlePath -Algorithm SHA1).Hash.ToUpperInvariant()
$bundleSha256 = (Get-FileHash -LiteralPath $BundlePath -Algorithm SHA256).Hash.ToUpperInvariant()
if ($bundleSha1 -ne $release.sha1 -or $bundleSha256 -ne $release.sha256) {
    throw "Upstream runtime bundle hash mismatch: '$BundlePath'."
}

$packageName = "DesktopGoldenEye-Windows-x86-$Version"
$stagingRoot = Join-Path $repositoryRoot '.work\package-windows'
$expandedRoot = Join-Path $stagingRoot 'upstream'
$packageRoot = Join-Path $stagingRoot $packageName
if (Test-Path -LiteralPath $stagingRoot) {
    Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $expandedRoot -Force | Out-Null
Expand-Archive -LiteralPath $BundlePath -DestinationPath $expandedRoot
$upstreamRuntime = Join-Path $expandedRoot '1964'
foreach ($relativePath in @('1964.exe', 'BUNDLE_README.txt', 'source.tar.xz', 'plugin\GLideN64.dll', 'plugin\Mouse_Injector.dll', 'plugin\AziAudio.dll')) {
    if (-not (Test-Path -LiteralPath (Join-Path $upstreamRuntime $relativePath) -PathType Leaf)) {
        throw "Verified bundle is missing required runtime file: 1964\$relativePath"
    }
}

New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
Copy-Item -LiteralPath $upstreamRuntime -Destination (Join-Path $packageRoot '1964') -Recurse
Copy-Item -LiteralPath $core -Destination (Join-Path $packageRoot '1964\DesktopGoldenEye.exe')
$packagedSaveDirectory = Join-Path $packageRoot '1964\save'
if (Test-Path -LiteralPath $packagedSaveDirectory) {
    Remove-Item -LiteralPath $packagedSaveDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $packagedSaveDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'launcher\windows') -Destination (Join-Path $packageRoot 'launcher') -Recurse
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'launcher\windows\DesktopGoldenEye.cmd') -Destination $packageRoot
foreach ($file in @('LICENSE', 'NOTICE.md', 'THIRD_PARTY_NOTICES.md')) {
    Copy-Item -LiteralPath (Join-Path $repositoryRoot $file) -Destination $packageRoot
}

$revisionOutput = & git -c 'safe.directory=*' -c 'core.autocrlf=false' -c 'core.filemode=false' -C $repositoryRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or -not $revisionOutput) { throw 'Could not determine the DesktopGoldenEye source revision.' }
$revision = $revisionOutput.Trim()
$workingTreeStatus = @(& git -c 'safe.directory=*' -c 'core.autocrlf=false' -c 'core.filemode=false' -C $repositoryRoot status --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Could not determine whether the DesktopGoldenEye source tree is clean.' }
$sourceDirty = $workingTreeStatus.Count -ne 0
if ($sourceDirty -and $Version -notmatch '(?i)(dev|alpha|local)') {
    throw 'Refusing to create a non-development release from a dirty source tree.'
}
$manifestFiles = [ordered]@{}
foreach ($relativePath in @('1964\DesktopGoldenEye.exe', '1964\plugin\GLideN64.dll', '1964\plugin\Mouse_Injector.dll', '1964\plugin\AziAudio.dll')) {
    $manifestFiles[$relativePath] = (Get-FileHash -LiteralPath (Join-Path $packageRoot $relativePath) -Algorithm SHA256).Hash.ToUpperInvariant()
}
[ordered]@{
    product = 'DesktopGoldenEye'
    version = $Version
    sourceRevision = $revision
    sourceDirty = $sourceDirty
    createdAtUtc = [DateTime]::UtcNow.ToString('o')
    platform = 'Windows x86'
    romIncluded = $false
    upstreamBundle = [ordered]@{ url = $release.url; sha1 = $bundleSha1; sha256 = $bundleSha256 }
    activeFiles = $manifestFiles
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $packageRoot 'release-manifest.json') -Encoding UTF8

@"
DESKTOPGOLDENEYE

1. Extract the complete folder. Do not run the game from inside the zip.
2. Double-click DesktopGoldenEye.cmd.
3. Browse to your legally obtained, unmodified US GoldenEye 007 ROM.
4. Press PLAY GOLDENEYE.

The ROM is verified locally and is never copied into this package.
Default controls: WASD move, mouse aim, left-click fire, right-click aim,
mouse wheel weapons, R reload, E use/cancel, Q accept, Ctrl crouch.
Press 4 to release or recapture the mouse.

Source revision: $revision
Source: https://github.com/martin2844/DesktopGoldenEye
See THIRD_PARTY_NOTICES.md for runtime component notices.
"@ | Set-Content -LiteralPath (Join-Path $packageRoot 'README-FIRST.txt') -Encoding UTF8

$romFiles = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Where-Object { $_.Extension -in @('.z64', '.v64', '.n64', '.rom') })
if ($romFiles.Count -ne 0) {
    throw "Release safety check found a ROM-like file: $($romFiles[0].FullName)"
}
& (Join-Path $PSScriptRoot 'test-desktopgoldeneye-package.ps1') -PackageRoot $packageRoot

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$archive = Join-Path $OutputDirectory "$packageName.zip"
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
Compress-Archive -LiteralPath $packageRoot -DestinationPath $archive -CompressionLevel Optimal
$archiveHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToUpperInvariant()
Write-Host "Packaged $archive"
Write-Host "SHA-256 $archiveHash"
