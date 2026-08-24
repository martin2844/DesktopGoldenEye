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
    param(
        [switch]$ExpectFailure,
        [string]$CacheParentOverride = $cacheParent
    )

    $process = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', ('"{0}"' -f $bootstrap),
        '-TestCacheParent', ('"{0}"' -f $CacheParentOverride),
        '-NoLaunch'
    ) -Wait -PassThru
    if ($ExpectFailure -and $process.ExitCode -eq 0) { throw 'Broken portable payload unexpectedly installed.' }
    if (-not $ExpectFailure -and $process.ExitCode -ne 0) { throw "Portable bootstrap failed with exit code $($process.ExitCode)." }
}

try {
    New-Item -ItemType Directory -Path $harness -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'packaging\windows\portable-bootstrap.ps1') -Destination $bootstrap
    Copy-Item -LiteralPath $archive -Destination $payload

    $untrustedCache = Join-Path $env:TEMP ("untrusted-portable-cache-" + [guid]::NewGuid().ToString('N'))
    Invoke-Bootstrap -ExpectFailure -CacheParentOverride $untrustedCache
    if (Test-Path -LiteralPath $untrustedCache) {
        throw 'A rejected portable cache override created or changed its target.'
    }

    $unownedInstallRoot = Join-Path $cacheParent 'Portable'
    New-Item -ItemType Directory -Path $unownedInstallRoot -Force | Out-Null
    $unownedSentinel = Join-Path $unownedInstallRoot 'user-file.txt'
    Set-Content -LiteralPath $unownedSentinel -Value 'must not be moved or deleted' -Encoding ASCII
    Invoke-Bootstrap -ExpectFailure
    if (-not (Test-Path -LiteralPath $unownedSentinel -PathType Leaf)) {
        throw 'Portable bootstrap changed an unrecognized pre-existing directory.'
    }
    Remove-Item -LiteralPath $unownedInstallRoot -Recurse -Force

    Invoke-Bootstrap
    $installRoot = Join-Path $cacheParent 'Portable'
    foreach ($required in @('.payload-id', 'DesktopGoldenEye.cmd', 'release-manifest.json', '1964\1964.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $installRoot $required) -PathType Leaf)) {
            throw "Portable first install is missing $required"
        }
    }

    $noOpSentinel = Join-Path $installRoot 'no-op-sentinel.txt'
    $payloadIdBefore = (Get-Content -LiteralPath (Join-Path $installRoot '.payload-id') -Raw).Trim()
    Set-Content -LiteralPath $noOpSentinel -Value 'must survive an unchanged-payload launch' -Encoding ASCII
    Invoke-Bootstrap
    $payloadIdAfter = (Get-Content -LiteralPath (Join-Path $installRoot '.payload-id') -Raw).Trim()
    if ($payloadIdAfter -ne $payloadIdBefore -or -not (Test-Path -LiteralPath $noOpSentinel -PathType Leaf)) {
        throw 'An unchanged portable payload was unnecessarily reinstalled.'
    }
    Remove-Item -LiteralPath $noOpSentinel -Force

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
