[CmdletBinding()]
param([Parameter(Mandatory)][string]$PackageArchive)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$archive = (Resolve-Path -LiteralPath $PackageArchive).Path
$testId = [guid]::NewGuid().ToString('N')
$testRoot = Join-Path $env:TEMP "DesktopGoldenEye-bootstrap-test-$testId"
$harness = Join-Path $testRoot 'harness'
$cacheParent = Join-Path $testRoot 'cache'
$bootstrap = Join-Path $harness 'portable-bootstrap.ps1'
$payload = Join-Path $harness 'payload.zip'

function Invoke-Bootstrap {
    param([switch]$ExpectFailure)

    $oldCache = $env:DESKTOPGOLDENEYE_PORTABLE_CACHE_PARENT
    $oldNoLaunch = $env:DESKTOPGOLDENEYE_PORTABLE_NO_LAUNCH
    try {
        $env:DESKTOPGOLDENEYE_PORTABLE_CACHE_PARENT = $cacheParent
        $env:DESKTOPGOLDENEYE_PORTABLE_NO_LAUNCH = '1'
        $process = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', ('"{0}"' -f $bootstrap)
        ) -Wait -PassThru
        if ($ExpectFailure -and $process.ExitCode -eq 0) { throw 'Broken portable payload unexpectedly installed.' }
        if (-not $ExpectFailure -and $process.ExitCode -ne 0) { throw "Portable bootstrap failed with exit code $($process.ExitCode)." }
    }
    finally {
        $env:DESKTOPGOLDENEYE_PORTABLE_CACHE_PARENT = $oldCache
        $env:DESKTOPGOLDENEYE_PORTABLE_NO_LAUNCH = $oldNoLaunch
    }
}

try {
    New-Item -ItemType Directory -Path $harness -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'packaging\windows\portable-bootstrap.ps1') -Destination $bootstrap
    Copy-Item -LiteralPath $archive -Destination $payload

    Invoke-Bootstrap
    $installRoot = Join-Path $cacheParent 'Portable'
    foreach ($required in @('.payload-id', 'DesktopGoldenEye.cmd', 'release-manifest.json', '1964\1964.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $installRoot $required) -PathType Leaf)) {
            throw "Portable first install is missing $required"
        }
    }

    $statePath = Join-Path $installRoot 'launcher-state.json'
    $savePath = Join-Path $installRoot '1964\save\bootstrap-test.sra'
    $backupPath = Join-Path $installRoot 'save-backups\bootstrap-test\bootstrap-test.sra'
    Set-Content -LiteralPath $statePath -Value '{"bootstrapTest":true}' -Encoding UTF8
    Set-Content -LiteralPath $savePath -Value 'save-preservation-probe' -Encoding ASCII
    New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
    Set-Content -LiteralPath $backupPath -Value 'backup-preservation-probe' -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $installRoot '.payload-id') -Value 'outdated-payload' -Encoding UTF8

    Invoke-Bootstrap
    foreach ($preserved in @($statePath, $savePath, $backupPath)) {
        if (-not (Test-Path -LiteralPath $preserved -PathType Leaf)) {
            throw "Portable update did not preserve $preserved"
        }
    }

    $goodPayload = Join-Path $testRoot 'good-payload.zip'
    Copy-Item -LiteralPath $payload -Destination $goodPayload
    $brokenRoot = Join-Path $testRoot 'broken'
    Expand-Archive -LiteralPath $payload -DestinationPath $brokenRoot
    $brokenProduct = Get-ChildItem -LiteralPath $brokenRoot -Directory | Select-Object -First 1
    if (-not $brokenProduct) { throw 'Test setup could not find the packaged product directory.' }
    New-Item -ItemType Directory -Path (Join-Path $brokenProduct.FullName '.payload-id') | Out-Null
    Remove-Item -LiteralPath $payload -Force
    Compress-Archive -LiteralPath $brokenProduct.FullName -DestinationPath $payload -CompressionLevel Fastest

    Set-Content -LiteralPath (Join-Path $installRoot '.payload-id') -Value 'outdated-for-broken-payload' -Encoding UTF8
    $markerBefore = (Get-Content -LiteralPath (Join-Path $installRoot '.payload-id') -Raw).Trim()
    Invoke-Bootstrap -ExpectFailure
    $markerAfter = (Get-Content -LiteralPath (Join-Path $installRoot '.payload-id') -Raw).Trim()
    if ($markerAfter -ne $markerBefore -or -not (Test-Path -LiteralPath $savePath -PathType Leaf)) {
        throw 'A rejected portable payload changed the installed runtime or preserved save.'
    }
    Copy-Item -LiteralPath $goodPayload -Destination $payload -Force

    Write-Host 'PASS: portable first install, no-op launch, update preservation, rejection, and rollback safety are complete.'
}
finally {
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
