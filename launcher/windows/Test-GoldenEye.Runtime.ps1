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
    'launcher\GoldenEye.Launcher.ps1',
    'launcher\GoldenEye.Runtime.psm1',
    'launcher\DesktopGoldenEye.cmd',
    'DesktopGoldenEye.cmd',
    'launcher-state.json'
)
foreach ($relativePath in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $InstallRoot $relativePath) -PathType Leaf)) {
        throw "Missing installed runtime file: $relativePath"
    }
}

$settings = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -RomPath $RomPath
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

$firstBackup = Backup-GoldenEyeSaves -InstallRoot $InstallRoot -Retention 2
$secondBackup = Backup-GoldenEyeSaves -InstallRoot $InstallRoot -Retention 2
if ($firstBackup -ne $secondBackup) {
    throw 'Content-aware save backup created a duplicate snapshot without save changes.'
}

$diagnostics = Get-GoldenEyeDiagnostics -InstallRoot $InstallRoot
@('DesktopGoldenEye diagnostics', 'Runtime complete: True', 'Selected core:', 'ROM: verified') | ForEach-Object {
    if (-not $diagnostics.Contains($_)) { throw "Diagnostics output is missing: $_" }
}
$desktopExecutable = Join-Path $InstallRoot '1964\DesktopGoldenEye.exe'
$legacyQBranchExecutable = Join-Path $InstallRoot '1964\1964-qbranch.exe'
if (Test-Path -LiteralPath $desktopExecutable -PathType Leaf) {
    $selectedExecutable = Get-QualityRuntimeExecutable -InstallRoot $InstallRoot
    if ((Split-Path -Leaf $selectedExecutable) -ne 'DesktopGoldenEye.exe') {
        throw 'The launcher did not prefer the installed DesktopGoldenEye core.'
    }
    if (-not $diagnostics.Contains('Selected core: DesktopGoldenEye.exe')) {
        throw 'Diagnostics did not identify the selected DesktopGoldenEye core.'
    }
}
elseif (Test-Path -LiteralPath $legacyQBranchExecutable -PathType Leaf) {
    Write-Warning 'Using legacy 1964-qbranch.exe filename; rebuild to install DesktopGoldenEye.exe.'
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
