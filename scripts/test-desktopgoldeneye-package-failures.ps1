[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PackageRoot,
    [Parameter(Mandatory)][string]$BundlePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourcePackage = (Resolve-Path -LiteralPath $PackageRoot).Path
$sourceBundle = (Resolve-Path -LiteralPath $BundlePath).Path
$testRoot = Join-Path $env:TEMP ("DesktopGoldenEye-package-failure-test-" + [guid]::NewGuid().ToString('N'))

function Assert-FailsWith {
    param(
        [Parameter(Mandatory)][scriptblock]$Action,
        [Parameter(Mandatory)][string]$Pattern
    )

    $failedAsExpected = $false
    $actualMessage = '<no failure>'
    try { & $Action }
    catch {
        $actualMessage = $_.Exception.Message
        $failedAsExpected = $actualMessage -match $Pattern
    }
    if (-not $failedAsExpected) { throw "Expected failure matching '$Pattern' did not occur. Actual: $actualMessage" }
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    Copy-Item -LiteralPath $sourcePackage -Destination $testRoot -Recurse
    $testPackage = Join-Path $testRoot (Split-Path -Leaf $sourcePackage)
    $packageTest = Join-Path $PSScriptRoot 'test-desktopgoldeneye-package.ps1'

    $romProbe = Join-Path $testPackage 'accidental-rom.z64'
    Set-Content -LiteralPath $romProbe -Value 'not-a-rom' -Encoding ASCII
    Assert-FailsWith -Pattern 'ROM-like file' -Action { & $packageTest -PackageRoot $testPackage }
    Remove-Item -LiteralPath $romProbe -Force

    $stateProbe = Join-Path $testPackage 'launcher-state.json'
    Set-Content -LiteralPath $stateProbe -Value '{}' -Encoding ASCII
    Assert-FailsWith -Pattern 'player-specific launcher state' -Action { & $packageTest -PackageRoot $testPackage }
    Remove-Item -LiteralPath $stateProbe -Force

    $saveProbe = Join-Path $testPackage '1964\save\accidental-save.sra'
    Set-Content -LiteralPath $saveProbe -Value 'save' -Encoding ASCII
    Assert-FailsWith -Pattern 'prebuilt save' -Action { & $packageTest -PackageRoot $testPackage }
    Remove-Item -LiteralPath $saveProbe -Force

    $forbiddenProbe = Join-Path $testPackage '1964\plugin\Jabo_Direct3D8.dll'
    Set-Content -LiteralPath $forbiddenProbe -Value 'forbidden' -Encoding ASCII
    Assert-FailsWith -Pattern 'unused or out-of-scope runtime file' -Action { & $packageTest -PackageRoot $testPackage }
    Remove-Item -LiteralPath $forbiddenProbe -Force

    $manifestPath = Join-Path $testPackage 'release-manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $manifest.activeFiles.'1964\1964.exe' = ('0' * 64)
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Assert-FailsWith -Pattern 'Manifest hash mismatch' -Action { & $packageTest -PackageRoot $testPackage }

    $corruptBundle = Join-Path $testRoot 'corrupt-upstream.zip'
    Copy-Item -LiteralPath $sourceBundle -Destination $corruptBundle
    $stream = [System.IO.File]::Open($corruptBundle, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
    try {
        $original = $stream.ReadByte()
        $stream.Position = 0
        $stream.WriteByte(($original -bxor 0xFF))
    }
    finally { $stream.Dispose() }
    $packageScript = Join-Path $PSScriptRoot 'package-desktopgoldeneye-windows.ps1'
    Assert-FailsWith -Pattern 'bundle hash mismatch' -Action {
        & $packageScript -Version '0.0.0.0-local' -BundlePath $corruptBundle -OutputDirectory (Join-Path $testRoot 'out')
    }

    Write-Host 'PASS: package rejects ROMs, state, saves, unused plugins, bad manifests, and corrupted upstream input.'
}
finally {
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
