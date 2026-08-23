[CmdletBinding()]
param(
    [string]$InstallRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'GoldenEye.Runtime.psm1') -Force

[System.Windows.Forms.Application]::EnableVisualStyles()
$settings = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

$paper = [System.Drawing.Color]::FromArgb(244, 241, 232)
$paperRaised = [System.Drawing.Color]::FromArgb(252, 250, 244)
$ink = [System.Drawing.Color]::FromArgb(29, 31, 27)
$inkSoft = [System.Drawing.Color]::FromArgb(91, 94, 86)
$charcoal = [System.Drawing.Color]::FromArgb(31, 35, 29)
$charcoalRaised = [System.Drawing.Color]::FromArgb(44, 49, 40)
$cream = [System.Drawing.Color]::FromArgb(224, 218, 200)
$red = [System.Drawing.Color]::FromArgb(174, 39, 46)
$redHover = [System.Drawing.Color]::FromArgb(194, 49, 56)
$olive = [System.Drawing.Color]::FromArgb(92, 102, 76)
$success = [System.Drawing.Color]::FromArgb(61, 112, 73)
$warning = [System.Drawing.Color]::FromArgb(155, 93, 34)

function New-Font {
    param([float]$Size, [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular)
    New-Object System.Drawing.Font('Bahnschrift', $Size, $Style, [System.Drawing.GraphicsUnit]::Point)
}

function New-TextLabel {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [float]$Size = 10,
        [System.Drawing.Color]$Color = $ink,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Font = New-Font -Size $Size -Style $Style
    $label.ForeColor = $Color
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label
}

function New-SectionRule {
    param([int]$Y)
    $rule = New-Object System.Windows.Forms.Panel
    $rule.Location = New-Object System.Drawing.Point(38, $Y)
    $rule.Size = New-Object System.Drawing.Size(610, 1)
    $rule.BackColor = [System.Drawing.Color]::FromArgb(205, 199, 183)
    $rule
}

function Style-Field {
    param([System.Windows.Forms.Control]$Control)
    $Control.Font = New-Font -Size 10
    $Control.BackColor = $paperRaised
    $Control.ForeColor = $ink
}

function Add-ResolutionOption {
    param([System.Windows.Forms.ComboBox]$Combo, [int]$Width, [int]$Height, [switch]$Native)
    $suffix = if ($Native) { '  -  NATIVE' } else { '' }
    $value = "$Width x $Height$suffix"
    if (-not $Combo.Items.Contains($value)) { [void]$Combo.Items.Add($value) }
}

function Get-Resolution {
    param([string]$Text)
    if ($Text -notmatch '^(\d+) x (\d+)') { throw 'Choose a valid display resolution.' }
    [pscustomobject]@{ Width = [int]$Matches[1]; Height = [int]$Matches[2] }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'GoldenEye // Q Branch Launcher'
$form.ClientSize = New-Object System.Drawing.Size(1040, 700)
$form.MinimumSize = New-Object System.Drawing.Size(1056, 739)
$form.MaximumSize = New-Object System.Drawing.Size(1056, 739)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.BackColor = $paper
$form.ForeColor = $ink
$form.Font = New-Font -Size 10
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$form.KeyPreview = $true

$left = New-Object System.Windows.Forms.Panel
$left.Location = New-Object System.Drawing.Point(0, 0)
$left.Size = New-Object System.Drawing.Size(330, 700)
$left.BackColor = $charcoal
$form.Controls.Add($left)

$classification = New-TextLabel -Text 'Q BRANCH  /  FIELD SYSTEMS' -X 30 -Y 29 -Width 260 -Height 22 -Size 9 -Color $cream -Style Bold
$left.Controls.Add($classification)

$accent = New-Object System.Windows.Forms.Panel
$accent.Location = New-Object System.Drawing.Point(30, 62)
$accent.Size = New-Object System.Drawing.Size(52, 5)
$accent.BackColor = $red
$left.Controls.Add($accent)

$title = New-TextLabel -Text "GOLDENEYE`n007" -X 27 -Y 82 -Width 270 -Height 112 -Size 31 -Color $paperRaised -Style Bold
$left.Controls.Add($title)

$edition = New-TextLabel -Text 'QUALITY RUNTIME  /  WINDOWS' -X 31 -Y 204 -Width 260 -Height 20 -Size 9 -Color ([System.Drawing.Color]::FromArgb(167, 174, 153)) -Style Bold
$left.Controls.Add($edition)

$brief = New-TextLabel -Text 'Verified 1964GEPD, GLideN64, and a launcher-owned modern input profile.' -X 31 -Y 244 -Width 255 -Height 62 -Size 10 -Color $cream
$left.Controls.Add($brief)

$left.Controls.Add((New-TextLabel -Text 'FIELD CONTROLS' -X 31 -Y 342 -Width 220 -Height 24 -Size 9 -Color ([System.Drawing.Color]::FromArgb(167, 174, 153)) -Style Bold))
$bindings = @(
    @('W A S D', 'Move / strafe'),
    @('MOUSE', 'Direct camera aim'),
    @('LMB / RMB', 'Fire / precision aim'),
    @('R / E / Q', 'Reload / use / weapon'),
    @('CTRL', 'Hold to crouch'),
    @('4', 'Release or recapture mouse')
)
$bindingY = 376
foreach ($binding in $bindings) {
    $left.Controls.Add((New-TextLabel -Text $binding[0] -X 31 -Y $bindingY -Width 95 -Height 21 -Size 9 -Color $paperRaised -Style Bold))
    $left.Controls.Add((New-TextLabel -Text $binding[1] -X 131 -Y $bindingY -Width 165 -Height 21 -Size 9 -Color $cream))
    $bindingY += 32
}

$leftStatus = New-TextLabel -Text 'ROM CHECK PENDING' -X 31 -Y 641 -Width 265 -Height 24 -Size 9 -Color ([System.Drawing.Color]::FromArgb(196, 159, 91)) -Style Bold
$left.Controls.Add($leftStatus)

$main = New-Object System.Windows.Forms.Panel
$main.Location = New-Object System.Drawing.Point(330, 0)
$main.Size = New-Object System.Drawing.Size(710, 700)
$main.BackColor = $paper
$form.Controls.Add($main)

$main.Controls.Add((New-TextLabel -Text 'MISSION CONFIGURATION' -X 38 -Y 29 -Width 420 -Height 34 -Size 22 -Color $ink -Style Bold))
$main.Controls.Add((New-TextLabel -Text 'Tune the game once. These settings are applied before every launch.' -X 40 -Y 68 -Width 560 -Height 25 -Size 10 -Color $inkSoft))

$main.Controls.Add((New-TextLabel -Text 'GAME FILE' -X 40 -Y 113 -Width 130 -Height 20 -Size 9 -Color $olive -Style Bold))
$romBox = New-Object System.Windows.Forms.TextBox
$romBox.Location = New-Object System.Drawing.Point(40, 139)
$romBox.Size = New-Object System.Drawing.Size(494, 27)
$romBox.Text = [string]$settings.romPath
$romBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
Style-Field $romBox
$main.Controls.Add($romBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = 'CHOOSE ROM'
$browseButton.Location = New-Object System.Drawing.Point(545, 137)
$browseButton.Size = New-Object System.Drawing.Size(103, 31)
$browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$browseButton.FlatAppearance.BorderColor = $olive
$browseButton.BackColor = $paper
$browseButton.ForeColor = $ink
$browseButton.Font = New-Font -Size 8.5 -Style Bold
$main.Controls.Add($browseButton)

$romStatus = New-TextLabel -Text 'Choose the unmodified US GoldenEye ROM.' -X 40 -Y 177 -Width 610 -Height 21 -Size 8.5 -Color $inkSoft
$main.Controls.Add($romStatus)
$main.Controls.Add((New-SectionRule -Y 211))

$main.Controls.Add((New-TextLabel -Text 'DISPLAY' -X 40 -Y 235 -Width 130 -Height 20 -Size 9 -Color $olive -Style Bold))
$main.Controls.Add((New-TextLabel -Text 'Mode' -X 40 -Y 269 -Width 90 -Height 20 -Size 9 -Color $inkSoft))
$displayCombo = New-Object System.Windows.Forms.ComboBox
$displayCombo.Location = New-Object System.Drawing.Point(40, 292)
$displayCombo.Size = New-Object System.Drawing.Size(185, 28)
$displayCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('Fullscreen', 'Borderless', 'Windowed') | ForEach-Object { [void]$displayCombo.Items.Add($_) }
$displayCombo.SelectedItem = [string]$settings.displayMode
Style-Field $displayCombo
$main.Controls.Add($displayCombo)

$main.Controls.Add((New-TextLabel -Text 'Resolution' -X 244 -Y 269 -Width 120 -Height 20 -Size 9 -Color $inkSoft))
$resolutionCombo = New-Object System.Windows.Forms.ComboBox
$resolutionCombo.Location = New-Object System.Drawing.Point(244, 292)
$resolutionCombo.Size = New-Object System.Drawing.Size(205, 28)
$resolutionCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
Add-ResolutionOption -Combo $resolutionCombo -Width $screen.Width -Height $screen.Height -Native
@(@(3840,2160), @(2560,1440), @(1920,1080), @(1600,900), @(1280,720)) | ForEach-Object { Add-ResolutionOption -Combo $resolutionCombo -Width $_[0] -Height $_[1] }
Style-Field $resolutionCombo
$main.Controls.Add($resolutionCombo)

$vsyncCheck = New-Object System.Windows.Forms.CheckBox
$vsyncCheck.Text = 'V-sync'
$vsyncCheck.Location = New-Object System.Drawing.Point(478, 291)
$vsyncCheck.Size = New-Object System.Drawing.Size(95, 30)
$vsyncCheck.Checked = [bool]$settings.verticalSync
$vsyncCheck.Font = New-Font -Size 9.5
$vsyncCheck.ForeColor = $ink
$main.Controls.Add($vsyncCheck)

$latencyNote = New-TextLabel -Text 'V-sync is off by default for lower mouse latency.' -X 40 -Y 333 -Width 500 -Height 20 -Size 8.5 -Color $inkSoft
$main.Controls.Add($latencyNote)
$main.Controls.Add((New-SectionRule -Y 363))

$main.Controls.Add((New-TextLabel -Text 'CONTROLS' -X 40 -Y 387 -Width 130 -Height 20 -Size 9 -Color $olive -Style Bold))
$main.Controls.Add((New-TextLabel -Text 'Behavior' -X 40 -Y 421 -Width 100 -Height 20 -Size 9 -Color $inkSoft))
$controlsCombo = New-Object System.Windows.Forms.ComboBox
$controlsCombo.Location = New-Object System.Drawing.Point(40, 444)
$controlsCombo.Size = New-Object System.Drawing.Size(255, 28)
$controlsCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('Modern FPS  -  RECOMMENDED', 'GoldenEye hybrid', 'Classic Mouse Injector') | ForEach-Object { [void]$controlsCombo.Items.Add($_) }
$presetIndex = @{ ModernFPS = 0; Hybrid = 1; ClassicInjector = 2 }
$controlsCombo.SelectedIndex = $presetIndex[[string]$settings.controlPreset]
Style-Field $controlsCombo
$main.Controls.Add($controlsCombo)

$main.Controls.Add((New-TextLabel -Text 'Mouse sensitivity' -X 325 -Y 421 -Width 150 -Height 20 -Size 9 -Color $inkSoft))
$sensitivityValue = New-TextLabel -Text "$($settings.mouseSensitivityPercent)%" -X 566 -Y 421 -Width 80 -Height 20 -Size 9 -Color $red -Style Bold
$sensitivityValue.TextAlign = [System.Drawing.ContentAlignment]::TopRight
$main.Controls.Add($sensitivityValue)

$sensitivity = New-Object System.Windows.Forms.TrackBar
$sensitivity.Location = New-Object System.Drawing.Point(318, 442)
$sensitivity.Size = New-Object System.Drawing.Size(332, 38)
$sensitivity.Minimum = 5
$sensitivity.Maximum = 50
$sensitivity.TickFrequency = 5
$sensitivity.SmallChange = 1
$sensitivity.LargeChange = 5
$sensitivity.Value = [math]::Max(5, [math]::Min(50, [math]::Round([int]$settings.mouseSensitivityPercent / 5)))
$main.Controls.Add($sensitivity)

$controlDescription = New-TextLabel -Text '' -X 40 -Y 486 -Width 608 -Height 22 -Size 8.5 -Color $inkSoft
$main.Controls.Add($controlDescription)

$invertCheck = New-Object System.Windows.Forms.CheckBox
$invertCheck.Text = 'Invert mouse Y'
$invertCheck.Location = New-Object System.Drawing.Point(40, 518)
$invertCheck.Size = New-Object System.Drawing.Size(150, 27)
$invertCheck.Checked = [bool]$settings.invertMouseY
$invertCheck.Font = New-Font -Size 9.5
$main.Controls.Add($invertCheck)

$accelerationCheck = New-Object System.Windows.Forms.CheckBox
$accelerationCheck.Text = 'Mouse acceleration'
$accelerationCheck.Location = New-Object System.Drawing.Point(204, 518)
$accelerationCheck.Size = New-Object System.Drawing.Size(175, 27)
$accelerationCheck.Checked = [bool]$settings.mouseAcceleration
$accelerationCheck.Font = New-Font -Size 9.5
$main.Controls.Add($accelerationCheck)

$main.Controls.Add((New-TextLabel -Text 'Vertical FOV' -X 403 -Y 520 -Width 100 -Height 20 -Size 9 -Color $inkSoft))
$fovValue = New-TextLabel -Text "$($settings.fieldOfView) deg" -X 582 -Y 520 -Width 65 -Height 20 -Size 9 -Color $red -Style Bold
$fovValue.TextAlign = [System.Drawing.ContentAlignment]::TopRight
$main.Controls.Add($fovValue)
$fov = New-Object System.Windows.Forms.TrackBar
$fov.Location = New-Object System.Drawing.Point(494, 512)
$fov.Size = New-Object System.Drawing.Size(103, 38)
$fov.Minimum = 45
$fov.Maximum = 100
$fov.TickFrequency = 15
$fov.Value = [math]::Max(45, [math]::Min(100, [int]$settings.fieldOfView))
$main.Controls.Add($fov)

$main.Controls.Add((New-SectionRule -Y 562))

$launchStatus = New-TextLabel -Text 'Ready to configure.' -X 40 -Y 591 -Width 395 -Height 42 -Size 9 -Color $inkSoft
$main.Controls.Add($launchStatus)

$launchButton = New-Object System.Windows.Forms.Button
$launchButton.Text = 'LAUNCH GOLDENEYE  >'
$launchButton.Location = New-Object System.Drawing.Point(445, 584)
$launchButton.Size = New-Object System.Drawing.Size(203, 50)
$launchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$launchButton.FlatAppearance.BorderSize = 0
$launchButton.BackColor = $red
$launchButton.ForeColor = [System.Drawing.Color]::White
$launchButton.Font = New-Font -Size 10.5 -Style Bold
$launchButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$main.Controls.Add($launchButton)
$form.AcceptButton = $launchButton

$footer = New-TextLabel -Text 'QUALITY ADAPTER  1964GEPD  /  MOUSE INJECTOR 2.3  /  GLIDEN64' -X 40 -Y 660 -Width 610 -Height 20 -Size 7.5 -Color ([System.Drawing.Color]::FromArgb(126, 128, 118)) -Style Bold
$main.Controls.Add($footer)

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($vsyncCheck, 'Can reduce tearing, but may add input latency.')
$toolTip.SetToolTip($accelerationCheck, 'Off is recommended for consistent muscle memory.')
$toolTip.SetToolTip($fov, '60 degrees vertical is approximately 91 degrees horizontal at 16:9.')

$setResolutionSelection = {
    $width = if ($displayCombo.SelectedItem -eq 'Windowed') { [int]$settings.windowedWidth } else { [int]$settings.fullscreenWidth }
    $height = if ($displayCombo.SelectedItem -eq 'Windowed') { [int]$settings.windowedHeight } else { [int]$settings.fullscreenHeight }
    $match = $resolutionCombo.Items | Where-Object { $_ -match "^$width x $height" } | Select-Object -First 1
    if (-not $match) {
        Add-ResolutionOption -Combo $resolutionCombo -Width $width -Height $height
        $match = $resolutionCombo.Items | Where-Object { $_ -match "^$width x $height" } | Select-Object -First 1
    }
    $resolutionCombo.SelectedItem = $match
}

$updateControlDescription = {
    $controlDescription.Text = switch ($controlsCombo.SelectedIndex) {
        0 { 'Direct camera aim, centered weapon and crosshair, no edge scrolling.' }
        1 { "Direct camera aim with GoldenEye's original floating weapon movement." }
        2 { 'Upstream cursor aiming: the reticle moves first, then scrolls the camera at the edge.' }
    }
}

$verifyRom = {
    try {
        $rom = Get-GoldenEyeRomInfo -RomPath $romBox.Text
        $romStatus.Text = "Verified US ROM  /  $($rom.Format.ToUpperInvariant())  /  SHA-1 $($rom.Sha1.Substring(0, 10))..."
        $romStatus.ForeColor = $success
        $leftStatus.Text = 'ROM VERIFIED  /  READY'
        $leftStatus.ForeColor = [System.Drawing.Color]::FromArgb(130, 187, 139)
        $launchButton.Enabled = $true
        return $true
    }
    catch {
        $romStatus.Text = 'ROM not verified. Choose the unmodified US release.'
        $romStatus.ForeColor = $warning
        $leftStatus.Text = 'ROM CHECK REQUIRED'
        $leftStatus.ForeColor = [System.Drawing.Color]::FromArgb(196, 159, 91)
        $launchButton.Enabled = $false
        return $false
    }
}

$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = 'Choose GoldenEye 007 US ROM'
    $dialog.Filter = 'Nintendo 64 ROMs (*.z64;*.v64;*.n64)|*.z64;*.v64;*.n64|All files (*.*)|*.*'
    if ($romBox.Text -and (Test-Path -LiteralPath $romBox.Text)) {
        $dialog.InitialDirectory = Split-Path -Parent $romBox.Text
        $dialog.FileName = Split-Path -Leaf $romBox.Text
    }
    if ($dialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $romBox.Text = $dialog.FileName
        & $verifyRom | Out-Null
    }
    $dialog.Dispose()
})

$romBox.Add_Leave({ & $verifyRom | Out-Null })
$displayCombo.Add_SelectedIndexChanged({ & $setResolutionSelection })
$resolutionCombo.Add_SelectedIndexChanged({
    if ($null -ne $resolutionCombo.SelectedItem -and $null -ne $displayCombo.SelectedItem) {
        $draftResolution = Get-Resolution -Text ([string]$resolutionCombo.SelectedItem)
        if ($displayCombo.SelectedItem -eq 'Windowed') {
            $settings.windowedWidth = $draftResolution.Width
            $settings.windowedHeight = $draftResolution.Height
        }
        else {
            $settings.fullscreenWidth = $draftResolution.Width
            $settings.fullscreenHeight = $draftResolution.Height
        }
    }
})
$controlsCombo.Add_SelectedIndexChanged({ & $updateControlDescription })
$sensitivity.Add_ValueChanged({ $sensitivityValue.Text = "$($sensitivity.Value * 5)%" })
$fov.Add_ValueChanged({ $fovValue.Text = "$($fov.Value) deg" })
$launchButton.Add_MouseEnter({ $launchButton.BackColor = $redHover })
$launchButton.Add_MouseLeave({ $launchButton.BackColor = $red })

$launchButton.Add_Click({
    if (-not (& $verifyRom)) { return }
    try {
        $launchButton.Enabled = $false
        $browseButton.Enabled = $false
        $launchStatus.Text = 'Applying display and input profile...'
        $launchStatus.ForeColor = $olive
        $form.Refresh()

        $resolution = Get-Resolution -Text ([string]$resolutionCombo.SelectedItem)
        $next = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -RomPath $romBox.Text
        $next.displayMode = [string]$displayCombo.SelectedItem
        if ($next.displayMode -eq 'Windowed') {
            $next.windowedWidth = $resolution.Width
            $next.windowedHeight = $resolution.Height
        }
        else {
            $next.fullscreenWidth = $resolution.Width
            $next.fullscreenHeight = $resolution.Height
        }
        $next.verticalSync = $vsyncCheck.Checked
        $next.controlPreset = @('ModernFPS', 'Hybrid', 'ClassicInjector')[$controlsCombo.SelectedIndex]
        $next.mouseSensitivityPercent = $sensitivity.Value * 5
        $next.mouseAcceleration = $accelerationCheck.Checked
        $next.invertMouseY = $invertCheck.Checked
        $next.fieldOfView = $fov.Value

        $next = Save-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -Settings $next
        Set-GoldenEyeRuntimeSettings -InstallRoot $InstallRoot -Settings $next
        $process = Start-GoldenEyeRuntime -Runtime Quality -InstallRoot $InstallRoot -RomPath $next.romPath -Settings $next
        $launchStatus.Text = "GoldenEye started  /  PID $($process.Id)"
        $form.Hide()
        $form.Close()
    }
    catch {
        $launchButton.Enabled = $true
        $browseButton.Enabled = $true
        $launchStatus.Text = 'Launch failed. Review the message and try again.'
        $launchStatus.ForeColor = $warning
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "GoldenEye could not start.`r`n`r`n$($_.Exception.Message)",
            'Launch failed',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

& $setResolutionSelection
& $updateControlDescription
& $verifyRom | Out-Null
[void][System.Windows.Forms.Application]::Run($form)
