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

if (-not ('GoldenEyeRomOrderTest' -as [type])) {
    Add-Type @'
using System;
using System.IO;

public static class GoldenEyeRomOrderTest
{
    public static byte[] ToZ64(string path, string format)
    {
        byte[] data = File.ReadAllBytes(path);
        if (format == "v64") {
            for (int i = 0; i < data.Length; i += 2) {
                byte value = data[i]; data[i] = data[i + 1]; data[i + 1] = value;
            }
        } else if (format == "n64") {
            for (int i = 0; i < data.Length; i += 4) {
                byte a = data[i]; byte b = data[i + 1];
                data[i] = data[i + 3]; data[i + 1] = data[i + 2];
                data[i + 2] = b; data[i + 3] = a;
            }
        }
        return data;
    }

    public static void WriteOrder(byte[] z64, string format, string path)
    {
        byte[] data = (byte[])z64.Clone();
        if (format == "v64") {
            for (int i = 0; i < data.Length; i += 2) {
                byte value = data[i]; data[i] = data[i + 1]; data[i + 1] = value;
            }
        } else if (format == "n64") {
            for (int i = 0; i < data.Length; i += 4) {
                byte a = data[i]; byte b = data[i + 1];
                data[i] = data[i + 3]; data[i + 1] = data[i + 2];
                data[i + 2] = b; data[i + 3] = a;
            }
        }
        File.WriteAllBytes(path, data);
    }
}
'@
}

$romOrderTestRoot = Join-Path $env:TEMP ("DesktopGoldenEye-rom-order-test-" + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $romOrderTestRoot | Out-Null
    $z64Bytes = [GoldenEyeRomOrderTest]::ToZ64($rom.Path, $rom.Format)
    foreach ($format in @('z64', 'v64', 'n64')) {
        $testRomPath = Join-Path $romOrderTestRoot "GoldenEye007USA.$format"
        [GoldenEyeRomOrderTest]::WriteOrder($z64Bytes, $format, $testRomPath)
        $testRom = Get-GoldenEyeRomInfo -RomPath $testRomPath
        if ($testRom.Format -ne $format -or $testRom.CanonicalSha1 -ne $rom.CanonicalSha1) {
            throw "ROM byte-order validation failed for $format."
        }
    }

    $spacePathAliasRoot = Join-Path $romOrderTestRoot 'runtime path with spaces\roms'
    $legacyAlias = & (Get-Module GoldenEye.Runtime) {
        param($RomInfo, $AliasRoot)
        Get-RomLaunchAlias -RomInfo $RomInfo -AliasDirectory $AliasRoot
    } $rom $spacePathAliasRoot
    if (-not (Test-Path -LiteralPath $legacyAlias -PathType Leaf) -or
        (Get-FileHash -LiteralPath $legacyAlias -Algorithm SHA1).Hash.ToUpperInvariant() -ne $rom.Sha1) {
        throw 'The legacy core launch alias did not preserve a ROM selected from a path containing spaces.'
    }
    $spaceSafeArguments = Get-QualityRuntimeArguments -RomDirectory 'roms' -RomName (Split-Path -Leaf $legacyAlias) -UsingForkedCore $false
    if ($spaceSafeArguments -notmatch '^-r roms -g GoldenEye007USA\.(z64|v64|n64) ') {
        throw 'The legacy core did not receive a relative, space-safe ROM alias.'
    }

    $invalidRomPath = Join-Path $romOrderTestRoot 'invalid.z64'
    [System.IO.File]::WriteAllBytes($invalidRomPath, (New-Object byte[] 12582912))
    $invalidRejected = $false
    try { [void](Get-GoldenEyeRomInfo -RomPath $invalidRomPath) }
    catch { $invalidRejected = $_.Exception.Message -match 'Unsupported GoldenEye ROM' }
    if (-not $invalidRejected) { throw 'A same-size ROM with an unsupported hash was not rejected.' }

    $wrongSizeRomPath = Join-Path $romOrderTestRoot 'wrong-size.z64'
    [System.IO.File]::WriteAllBytes($wrongSizeRomPath, (New-Object byte[] 4))
    $wrongSizeRejected = $false
    try { [void](Get-GoldenEyeRomInfo -RomPath $wrongSizeRomPath) }
    catch { $wrongSizeRejected = $_.Exception.Message -match 'size' }
    if (-not $wrongSizeRejected) { throw 'A wrong-size ROM was not rejected.' }

    $missingRejected = $false
    try { [void](Get-GoldenEyeRomInfo -RomPath (Join-Path $romOrderTestRoot 'missing.z64')) }
    catch { $missingRejected = $true }
    if (-not $missingRejected) { throw 'A missing ROM path was not rejected.' }
}
finally {
    if (Test-Path -LiteralPath $romOrderTestRoot -PathType Container) {
        Remove-Item -LiteralPath $romOrderTestRoot -Recurse -Force
    }
}

$required = @(
    '1964\1964.exe',
    '1964\zlib.dll',
    '1964\msvcr100.dll',
    '1964\source.tar.xz',
    '1964\plugin\GLideN64.dll',
    '1964\plugin\Mouse_Injector.dll',
    'launcher\GoldenEye.ps1',
    'launcher\GoldenEye.Launcher.ps1',
    'launcher\GoldenEye.Runtime.psm1',
    'launcher\DesktopGoldenEye.cmd',
    'DesktopGoldenEye.cmd'
)
foreach ($relativePath in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot $relativePath) -PathType Leaf)) {
        throw "Missing installed runtime file: $relativePath"
    }
}

$selectionTestRoot = Join-Path $env:TEMP ("DesktopGoldenEye-core-selection-test-" + [guid]::NewGuid().ToString('N'))
try {
    $selectionRuntime = Join-Path $selectionTestRoot '1964'
    foreach ($relativePath in @(
        'BUNDLE_README.txt',
        'source.tar.xz',
        'zlib.dll',
        'msvcr100.dll',
        'plugin\mouseinjector.ini',
        'plugin\GLideN64.dll',
        'plugin\Mouse_Injector.dll',
        'plugin\AziAudio.dll',
        'DesktopGoldenEye.exe',
        '1964-qbranch.exe'
    )) {
        $path = Join-Path $selectionRuntime $relativePath
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        Set-Content -LiteralPath $path -Value 'selection-test' -Encoding ASCII
    }
    $experimentalOnlyIsQuality = & (Get-Module GoldenEye.Runtime) {
        param($TestRoot)
        Test-QualityRuntime -InstallRoot $TestRoot
    } $selectionTestRoot
    if ($experimentalOnlyIsQuality) {
        throw 'Experimental source-built cores were incorrectly accepted as the quality runtime.'
    }

    Set-Content -LiteralPath (Join-Path $selectionRuntime '1964.exe') -Value 'stable-selection-test' -Encoding ASCII
    $stableSelection = Get-QualityRuntimeExecutable -InstallRoot $selectionTestRoot
    if ((Split-Path -Leaf $stableSelection) -ne '1964.exe') {
        throw 'Experimental source-built cores took precedence over the release-qualified stable core.'
    }
}
finally {
    if (Test-Path -LiteralPath $selectionTestRoot -PathType Container) {
        Remove-Item -LiteralPath $selectionTestRoot -Recurse -Force
    }
}

$settings = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -RomPath $RomPath
$settings = Save-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -Settings $settings
Set-GoldenEyeRuntimeSettings -InstallRoot $InstallRoot -Settings $settings

$runtimeConfig = Get-Content -LiteralPath (Join-Path $InstallRoot '1964\1964.cfg') -Raw
@('VideoPlugin GLideN64.dll', 'InputPlugin Mouse_Injector.dll', 'GEFiringRateHack 1', 'GEDisableHeadRoll 1', 'PauseWhenInactive 1', 'AutoFullScreen 0') | ForEach-Object {
    if (-not $runtimeConfig.ToLowerInvariant().Contains($_.ToLowerInvariant())) { throw "1964 quality profile is missing: $_" }
}

$videoConfig = Get-Content -LiteralPath (Join-Path $InstallRoot '1964\plugin\GLideN64.ini') -Raw
@('video\verticalSync=0', 'video\multisampling=4', 'video\fxaa=0', 'texture\maxAnisotropy=16', 'generalEmulation\enableLOD=1', 'frameBufferEmulation\aspect=2', 'textureFilter\txHiresEnable=1', 'onScreenDisplay\showFPS=0') | ForEach-Object {
    if (-not $videoConfig.Contains($_)) { throw "GLideN64 quality profile is missing: $_" }
}
if ($videoConfig -match '@[A-Z_]+@') { throw 'GLideN64 quality profile contains an unresolved template token.' }

if ($settings.schemaVersion -ne 3 -or $settings.controlPreset -ne 'ModernFPS' -or $settings.antiAliasing -ne 'MSAA4' -or $settings.anisotropy -ne 16) {
    throw 'Launcher state did not migrate to the Modern FPS schema.'
}

$backupTestRoot = Join-Path $env:TEMP ("DesktopGoldenEye-save-test-" + [guid]::NewGuid().ToString('N'))
try {
    $backupTestSave = Join-Path $backupTestRoot '1964\save\goldeneye.sra'
    New-Item -ItemType Directory -Path (Split-Path -Parent $backupTestSave) -Force | Out-Null
    if ($null -ne (Backup-GoldenEyeSaves -InstallRoot $backupTestRoot -Retention 2)) {
        throw 'An empty save directory unexpectedly created a backup.'
    }
    Set-Content -LiteralPath (Join-Path (Split-Path -Parent $backupTestSave) 'ignored.txt') -Value 'not an emulator save' -Encoding ASCII
    if ($null -ne (Backup-GoldenEyeSaves -InstallRoot $backupTestRoot -Retention 2)) {
        throw 'A non-save file unexpectedly created a backup.'
    }
    Set-Content -LiteralPath $backupTestSave -Value 'save-version-1' -Encoding ASCII

    $firstBackup = Backup-GoldenEyeSaves -InstallRoot $backupTestRoot -Retention 2
    if (-not $firstBackup -or -not (Test-Path -LiteralPath (Join-Path $firstBackup 'manifest.json') -PathType Leaf)) {
        throw 'Save backup did not create a snapshot and manifest.'
    }
    $secondBackup = Backup-GoldenEyeSaves -InstallRoot $backupTestRoot -Retention 2
    if ($firstBackup -ne $secondBackup) {
        throw 'Content-aware save backup created a duplicate snapshot without save changes.'
    }

    Set-Content -LiteralPath $backupTestSave -Value 'save-version-2' -Encoding ASCII
    $thirdBackup = Backup-GoldenEyeSaves -InstallRoot $backupTestRoot -Retention 2
    if (-not $thirdBackup -or $thirdBackup -eq $firstBackup) {
        throw 'Changed save content did not create a new snapshot.'
    }
    Start-Sleep -Milliseconds 5
    Set-Content -LiteralPath $backupTestSave -Value 'save-version-3' -Encoding ASCII
    [void](Backup-GoldenEyeSaves -InstallRoot $backupTestRoot -Retention 2)
    $retainedBackups = @(Get-ChildItem -LiteralPath (Join-Path $backupTestRoot 'save-backups') -Directory)
    if ($retainedBackups.Count -ne 2) {
        throw "Save-backup retention expected 2 snapshots and found $($retainedBackups.Count)."
    }
}
finally {
    if (Test-Path -LiteralPath $backupTestRoot -PathType Container) {
        Remove-Item -LiteralPath $backupTestRoot -Recurse -Force
    }
}

$diagnostics = Get-GoldenEyeDiagnostics -InstallRoot $InstallRoot
@('DesktopGoldenEye diagnostics', 'Runtime complete: True', 'Selected core:', 'ROM: verified') | ForEach-Object {
    if (-not $diagnostics.Contains($_)) { throw "Diagnostics output is missing: $_" }
}
$selectedExecutable = Get-QualityRuntimeExecutable -InstallRoot $InstallRoot
if ((Split-Path -Leaf $selectedExecutable) -ne '1964.exe') {
    throw 'The v0.1 package did not select the release-qualified 1964GEPD core.'
}
if (-not $diagnostics.Contains('Selected core: 1964.exe')) {
    throw 'Diagnostics did not identify the selected 1964GEPD core.'
}

$legacyArguments = Get-QualityRuntimeArguments -RomDirectory 'D:\Roms' -RomName 'GoldenEye007USA.v64' -UsingForkedCore $false
if ($legacyArguments -ne '-r D:\Roms -g GoldenEye007USA.v64 -v GLideN64.dll -a AziAudio.dll -c Mouse_Injector.dll -o 9') {
    throw 'Legacy 1964GEPD launch arguments changed or regained incompatible quoting.'
}
$forkedArguments = Get-QualityRuntimeArguments -RomDirectory 'D:\My Roms' -RomName 'Golden Eye.v64' -UsingForkedCore $true -Fullscreen
if ($forkedArguments -ne '-r "D:\My Roms" -g "Golden Eye.v64" -v GLideN64.dll -a AziAudio.dll -c Mouse_Injector.dll -o 9 -f') {
    throw 'Forked-core quoted launch arguments changed unexpectedly.'
}

$mouseProfile = @(Get-Content -LiteralPath (Join-Path $InstallRoot '1964\plugin\mouseinjector.ini') | ForEach-Object { [int]$_ })
if ($mouseProfile.Count -ne 192) { throw 'Mouse Injector profile line count changed unexpectedly.' }
$expectedMouseValues = [ordered]@{
    144 = 1  # WASD
    146 = 0  # acceleration off
    147 = 0  # no independent weapon/crosshair drift
    150 = 0  # no cursor/edge-scroll aiming
    187 = 1  # centered crosshair visible
    189 = 1  # automatic mouse capture
    190 = 1  # release capture when focus is lost
}
foreach ($entry in $expectedMouseValues.GetEnumerator()) {
    if ($mouseProfile[[int]$entry.Key] -ne [int]$entry.Value) {
        throw "Modern FPS profile mismatch at Mouse Injector index $($entry.Key)."
    }
}

$parseErrors = $null
@(
    (Join-Path $PSScriptRoot 'GoldenEye.ps1'),
    (Join-Path $PSScriptRoot 'GoldenEye.Launcher.ps1'),
    (Join-Path $PSScriptRoot 'GoldenEye.Runtime.psm1')
) | ForEach-Object {
    [void][System.Management.Automation.Language.Parser]::ParseFile($_, [ref]$null, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { throw "PowerShell parse failure in '$_': $($parseErrors[0].Message)" }
}

if (-not ('GoldenEyeCaptureTestProbe' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class GoldenEyeCaptureTestProbe
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT point);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    public static extern bool GetClientRect(IntPtr window, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr window, ref POINT point);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr window, IntPtr after, int x, int y, int width, int height, uint flags);
}
'@
}

$originalCursor = New-Object GoldenEyeCaptureTestProbe+POINT
[void][GoldenEyeCaptureTestProbe]::GetCursorPos([ref]$originalCursor)
$windowScript = @'
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = 'GoldenEye capture regression probe'
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.Location = New-Object System.Drawing.Point(100, 100)
$form.ClientSize = New-Object System.Drawing.Size(640, 480)
[void][System.Windows.Forms.Application]::Run($form)
'@
$encodedWindowScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($windowScript))
$probeProcess = Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList @(
    '-NoProfile', '-STA', '-EncodedCommand', $encodedWindowScript
) -PassThru
try {
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        if ($probeProcess.HasExited) { throw 'Window capture test process exited before creating a window.' }
        $probeProcess.Refresh()
        if ($probeProcess.MainWindowHandle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)
    if ($probeProcess.MainWindowHandle -eq [IntPtr]::Zero) { throw 'Window capture test process did not create a window.' }

    [void][GoldenEyeCaptureTestProbe]::SetWindowPos($probeProcess.MainWindowHandle, [IntPtr]::Zero, 100, 100, 640, 480, 0)
    [void][GoldenEyeCaptureTestProbe]::SetCursorPos(2000, 1200)
    & (Get-Module GoldenEye.Runtime) {
        param($TargetProcess)
        Initialize-QualityWindowInputCapture -Process $TargetProcess
    } $probeProcess

    $cursor = New-Object GoldenEyeCaptureTestProbe+POINT
    $client = New-Object GoldenEyeCaptureTestProbe+RECT
    $clientOrigin = New-Object GoldenEyeCaptureTestProbe+POINT
    [void][GoldenEyeCaptureTestProbe]::GetCursorPos([ref]$cursor)
    [void][GoldenEyeCaptureTestProbe]::GetClientRect($probeProcess.MainWindowHandle, [ref]$client)
    [void][GoldenEyeCaptureTestProbe]::ClientToScreen($probeProcess.MainWindowHandle, [ref]$clientOrigin)
    $insideClient = $cursor.X -ge $clientOrigin.X -and $cursor.X -lt ($clientOrigin.X + $client.Right) -and
        $cursor.Y -ge $clientOrigin.Y -and $cursor.Y -lt ($clientOrigin.Y + $client.Bottom)
    if (-not $insideClient) { throw 'Windowed input capture did not seed the cursor inside the game client area.' }
}
finally {
    if ($null -ne $probeProcess -and -not $probeProcess.HasExited) {
        Stop-Process -Id $probeProcess.Id -Force
        Wait-Process -Id $probeProcess.Id -ErrorAction SilentlyContinue
    }
    [void][GoldenEyeCaptureTestProbe]::SetCursorPos($originalCursor.X, $originalCursor.Y)
}

Write-Host "PASS: ROM verified as $($rom.Format); graphics QoL, save backups, diagnostics, Modern FPS controls, and windowed mouse capture are complete."
