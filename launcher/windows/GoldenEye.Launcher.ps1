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
    $rule.Size = New-Object System.Drawing.Size(670, 1)
    $rule.BackColor = [System.Drawing.Color]::FromArgb(205, 199, 183)
    $rule
}

function Style-Field {
    param([System.Windows.Forms.Control]$Control)
    $Control.Font = New-Font -Size 10
    $Control.BackColor = $paperRaised
    $Control.ForeColor = $ink
}

function New-UtilityButton {
    param([string]$Text, [int]$X, [int]$Y, [int]$Width = 135)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, 34)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = $olive
    $button.BackColor = $paperRaised
    $button.ForeColor = $ink
    $button.Font = New-Font -Size 8.5 -Style Bold
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button
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
$form.Text = 'DesktopGoldenEye'
$form.ClientSize = New-Object System.Drawing.Size(1080, 760)
$form.MinimumSize = New-Object System.Drawing.Size(1096, 799)
$form.MaximumSize = New-Object System.Drawing.Size(1096, 799)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.BackColor = $paper
$form.ForeColor = $ink
$form.Font = New-Font -Size 10
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$form.KeyPreview = $true

$left = New-Object System.Windows.Forms.Panel
$left.Location = New-Object System.Drawing.Point(0, 0)
$left.Size = New-Object System.Drawing.Size(330, 760)
$left.BackColor = $charcoal
$form.Controls.Add($left)

$classification = New-TextLabel -Text 'DESKTOP EDITION  /  FIELD SYSTEMS' -X 30 -Y 29 -Width 260 -Height 22 -Size 9 -Color $cream -Style Bold
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

$brief = New-TextLabel -Text 'Load your ROM. Play GoldenEye with modern mouse aiming and desktop quality settings.' -X 31 -Y 244 -Width 255 -Height 62 -Size 10 -Color $cream
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

$leftStatus = New-TextLabel -Text 'ROM CHECK PENDING' -X 31 -Y 701 -Width 265 -Height 24 -Size 9 -Color ([System.Drawing.Color]::FromArgb(196, 159, 91)) -Style Bold
$left.Controls.Add($leftStatus)

$main = New-Object System.Windows.Forms.Panel
$main.Location = New-Object System.Drawing.Point(330, 0)
$main.Size = New-Object System.Drawing.Size(750, 760)
$main.BackColor = $paper
$form.Controls.Add($main)

$main.Controls.Add((New-TextLabel -Text 'MISSION CONFIGURATION' -X 38 -Y 29 -Width 420 -Height 34 -Size 22 -Color $ink -Style Bold))
$main.Controls.Add((New-TextLabel -Text 'Tune the game once. These settings are applied before every launch.' -X 40 -Y 68 -Width 560 -Height 25 -Size 10 -Color $inkSoft))

$main.Controls.Add((New-TextLabel -Text 'GAME FILE' -X 40 -Y 113 -Width 130 -Height 20 -Size 9 -Color $olive -Style Bold))
$romBox = New-Object System.Windows.Forms.TextBox
$romBox.Location = New-Object System.Drawing.Point(40, 139)
$romBox.Size = New-Object System.Drawing.Size(514, 27)
$romBox.Text = [string]$settings.romPath
$romBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
Style-Field $romBox
$main.Controls.Add($romBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = 'CHOOSE ROM'
$browseButton.Location = New-Object System.Drawing.Point(565, 137)
$browseButton.Size = New-Object System.Drawing.Size(143, 31)
$browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$browseButton.FlatAppearance.BorderColor = $olive
$browseButton.BackColor = $paper
$browseButton.ForeColor = $ink
$browseButton.Font = New-Font -Size 8.5 -Style Bold
$main.Controls.Add($browseButton)

$romStatus = New-TextLabel -Text 'Choose the unmodified US GoldenEye ROM.' -X 40 -Y 177 -Width 610 -Height 21 -Size 8.5 -Color $inkSoft
$main.Controls.Add($romStatus)
$main.Controls.Add((New-SectionRule -Y 211))

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(38, 218)
$tabs.Size = New-Object System.Drawing.Size(674, 410)
$tabs.Font = New-Font -Size 9.5 -Style Bold
$main.Controls.Add($tabs)

$displayTab = New-Object System.Windows.Forms.TabPage
$displayTab.Text = '  DISPLAY  '
$displayTab.BackColor = $paper
$displayTab.UseVisualStyleBackColor = $false
$tabs.TabPages.Add($displayTab)

$controlsTab = New-Object System.Windows.Forms.TabPage
$controlsTab.Text = '  CONTROLS  '
$controlsTab.BackColor = $paper
$controlsTab.UseVisualStyleBackColor = $false
$tabs.TabPages.Add($controlsTab)

$systemTab = New-Object System.Windows.Forms.TabPage
$systemTab.Text = '  SAVES & TOOLS  '
$systemTab.BackColor = $paper
$systemTab.UseVisualStyleBackColor = $false
$tabs.TabPages.Add($systemTab)

$displayTab.Controls.Add((New-TextLabel -Text 'WINDOW' -X 22 -Y 22 -Width 130 -Height 20 -Size 9 -Color $olive -Style Bold))
$displayTab.Controls.Add((New-TextLabel -Text 'Mode' -X 22 -Y 55 -Width 90 -Height 20 -Size 9 -Color $inkSoft))
$displayCombo = New-Object System.Windows.Forms.ComboBox
$displayCombo.Location = New-Object System.Drawing.Point(22, 78)
$displayCombo.Size = New-Object System.Drawing.Size(185, 28)
$displayCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('Fullscreen', 'Borderless', 'Windowed') | ForEach-Object { [void]$displayCombo.Items.Add($_) }
$displayCombo.SelectedItem = [string]$settings.displayMode
Style-Field $displayCombo
$displayTab.Controls.Add($displayCombo)

$displayTab.Controls.Add((New-TextLabel -Text 'Resolution' -X 225 -Y 55 -Width 120 -Height 20 -Size 9 -Color $inkSoft))
$resolutionCombo = New-Object System.Windows.Forms.ComboBox
$resolutionCombo.Location = New-Object System.Drawing.Point(225, 78)
$resolutionCombo.Size = New-Object System.Drawing.Size(205, 28)
$resolutionCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
Add-ResolutionOption -Combo $resolutionCombo -Width $screen.Width -Height $screen.Height -Native
@(@(3840,2160), @(2560,1440), @(1920,1080), @(1600,900), @(1280,720)) | ForEach-Object { Add-ResolutionOption -Combo $resolutionCombo -Width $_[0] -Height $_[1] }
Style-Field $resolutionCombo
$displayTab.Controls.Add($resolutionCombo)

$vsyncCheck = New-Object System.Windows.Forms.CheckBox
$vsyncCheck.Text = 'V-sync (may add latency)'
$vsyncCheck.Location = New-Object System.Drawing.Point(453, 76)
$vsyncCheck.Size = New-Object System.Drawing.Size(185, 30)
$vsyncCheck.Checked = [bool]$settings.verticalSync
$vsyncCheck.Font = New-Font -Size 9.5
$vsyncCheck.ForeColor = $ink
$displayTab.Controls.Add($vsyncCheck)

$displayTab.Controls.Add((New-TextLabel -Text 'IMAGE QUALITY' -X 22 -Y 137 -Width 160 -Height 20 -Size 9 -Color $olive -Style Bold))
$displayTab.Controls.Add((New-TextLabel -Text 'Anti-aliasing' -X 22 -Y 170 -Width 120 -Height 20 -Size 9 -Color $inkSoft))
$aaCombo = New-Object System.Windows.Forms.ComboBox
$aaCombo.Location = New-Object System.Drawing.Point(22, 193)
$aaCombo.Size = New-Object System.Drawing.Size(185, 28)
$aaCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('Off  -  SHARPEST', 'FXAA  -  SOFT', '2x MSAA', '4x MSAA  -  QUALITY', '8x MSAA') | ForEach-Object { [void]$aaCombo.Items.Add($_) }
$aaIndex = @{ Off = 0; FXAA = 1; MSAA2 = 2; MSAA4 = 3; MSAA8 = 4 }
$aaCombo.SelectedIndex = $aaIndex[[string]$settings.antiAliasing]
Style-Field $aaCombo
$displayTab.Controls.Add($aaCombo)

$displayTab.Controls.Add((New-TextLabel -Text 'Anisotropic filtering' -X 225 -Y 170 -Width 160 -Height 20 -Size 9 -Color $inkSoft))
$anisotropyCombo = New-Object System.Windows.Forms.ComboBox
$anisotropyCombo.Location = New-Object System.Drawing.Point(225, 193)
$anisotropyCombo.Size = New-Object System.Drawing.Size(185, 28)
$anisotropyCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('Off', '2x', '4x', '8x', '16x  -  RECOMMENDED') | ForEach-Object { [void]$anisotropyCombo.Items.Add($_) }
$anisotropyCombo.SelectedIndex = @{ 0 = 0; 2 = 1; 4 = 2; 8 = 3; 16 = 4 }[[int]$settings.anisotropy]
Style-Field $anisotropyCombo
$displayTab.Controls.Add($anisotropyCombo)

$displayTab.Controls.Add((New-TextLabel -Text 'Aspect ratio' -X 428 -Y 170 -Width 120 -Height 20 -Size 9 -Color $inkSoft))
$aspectCombo = New-Object System.Windows.Forms.ComboBox
$aspectCombo.Location = New-Object System.Drawing.Point(428, 193)
$aspectCombo.Size = New-Object System.Drawing.Size(205, 28)
$aspectCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('Widescreen 16:9', 'Original 4:3', 'Stretch to fill', 'Auto adjust') | ForEach-Object { [void]$aspectCombo.Items.Add($_) }
$aspectCombo.SelectedIndex = @{ Widescreen = 0; Original4x3 = 1; Stretch = 2; Adjust = 3 }[[string]$settings.aspectRatio]
Style-Field $aspectCombo
$displayTab.Controls.Add($aspectCombo)

$texturePackCheck = New-Object System.Windows.Forms.CheckBox
$texturePackCheck.Text = 'Enhanced HUD texture cache'
$texturePackCheck.Location = New-Object System.Drawing.Point(22, 250)
$texturePackCheck.Size = New-Object System.Drawing.Size(235, 28)
$texturePackCheck.Checked = [bool]$settings.texturePack
$texturePackCheck.Font = New-Font -Size 9.5
$displayTab.Controls.Add($texturePackCheck)

$fpsCheck = New-Object System.Windows.Forms.CheckBox
$fpsCheck.Text = 'Show FPS overlay'
$fpsCheck.Location = New-Object System.Drawing.Point(275, 250)
$fpsCheck.Size = New-Object System.Drawing.Size(175, 28)
$fpsCheck.Checked = [bool]$settings.showFps
$fpsCheck.Font = New-Font -Size 9.5
$displayTab.Controls.Add($fpsCheck)

$displayTab.Controls.Add((New-TextLabel -Text '4x MSAA and 16x filtering improve geometry and distant textures. Disable AA first if your GPU struggles.' -X 22 -Y 301 -Width 610 -Height 45 -Size 8.5 -Color $inkSoft))

$controlsTab.Controls.Add((New-TextLabel -Text 'AIM MODEL' -X 22 -Y 22 -Width 130 -Height 20 -Size 9 -Color $olive -Style Bold))
$controlsTab.Controls.Add((New-TextLabel -Text 'Behavior' -X 22 -Y 55 -Width 100 -Height 20 -Size 9 -Color $inkSoft))
$controlsCombo = New-Object System.Windows.Forms.ComboBox
$controlsCombo.Location = New-Object System.Drawing.Point(22, 78)
$controlsCombo.Size = New-Object System.Drawing.Size(255, 28)
$controlsCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
@('Modern FPS  -  RECOMMENDED', 'GoldenEye hybrid', 'Classic Mouse Injector') | ForEach-Object { [void]$controlsCombo.Items.Add($_) }
$presetIndex = @{ ModernFPS = 0; Hybrid = 1; ClassicInjector = 2 }
$controlsCombo.SelectedIndex = $presetIndex[[string]$settings.controlPreset]
Style-Field $controlsCombo
$controlsTab.Controls.Add($controlsCombo)

$controlsTab.Controls.Add((New-TextLabel -Text 'Mouse sensitivity' -X 305 -Y 55 -Width 150 -Height 20 -Size 9 -Color $inkSoft))
$sensitivityValue = New-TextLabel -Text "$($settings.mouseSensitivityPercent)%" -X 555 -Y 55 -Width 80 -Height 20 -Size 9 -Color $red -Style Bold
$sensitivityValue.TextAlign = [System.Drawing.ContentAlignment]::TopRight
$controlsTab.Controls.Add($sensitivityValue)

$sensitivity = New-Object System.Windows.Forms.TrackBar
$sensitivity.Location = New-Object System.Drawing.Point(298, 76)
$sensitivity.Size = New-Object System.Drawing.Size(332, 38)
$sensitivity.Minimum = 5
$sensitivity.Maximum = 50
$sensitivity.TickFrequency = 5
$sensitivity.SmallChange = 1
$sensitivity.LargeChange = 5
$sensitivity.Value = [math]::Max(5, [math]::Min(50, [math]::Round([int]$settings.mouseSensitivityPercent / 5)))
$controlsTab.Controls.Add($sensitivity)

$controlDescription = New-TextLabel -Text '' -X 22 -Y 125 -Width 608 -Height 36 -Size 8.5 -Color $inkSoft
$controlsTab.Controls.Add($controlDescription)

$invertCheck = New-Object System.Windows.Forms.CheckBox
$invertCheck.Text = 'Invert mouse Y'
$invertCheck.Location = New-Object System.Drawing.Point(22, 180)
$invertCheck.Size = New-Object System.Drawing.Size(150, 27)
$invertCheck.Checked = [bool]$settings.invertMouseY
$invertCheck.Font = New-Font -Size 9.5
$controlsTab.Controls.Add($invertCheck)

$accelerationCheck = New-Object System.Windows.Forms.CheckBox
$accelerationCheck.Text = 'Mouse acceleration'
$accelerationCheck.Location = New-Object System.Drawing.Point(185, 180)
$accelerationCheck.Size = New-Object System.Drawing.Size(175, 27)
$accelerationCheck.Checked = [bool]$settings.mouseAcceleration
$accelerationCheck.Font = New-Font -Size 9.5
$controlsTab.Controls.Add($accelerationCheck)

$headRollCheck = New-Object System.Windows.Forms.CheckBox
$headRollCheck.Text = 'Reduce camera head roll'
$headRollCheck.Location = New-Object System.Drawing.Point(375, 180)
$headRollCheck.Size = New-Object System.Drawing.Size(215, 27)
$headRollCheck.Checked = [bool]$settings.disableHeadRoll
$headRollCheck.Font = New-Font -Size 9.5
$controlsTab.Controls.Add($headRollCheck)

$controlsTab.Controls.Add((New-TextLabel -Text 'Vertical field of view' -X 22 -Y 245 -Width 180 -Height 20 -Size 9 -Color $inkSoft))
$fovValue = New-TextLabel -Text "$($settings.fieldOfView) deg" -X 555 -Y 245 -Width 75 -Height 20 -Size 9 -Color $red -Style Bold
$fovValue.TextAlign = [System.Drawing.ContentAlignment]::TopRight
$controlsTab.Controls.Add($fovValue)
$fov = New-Object System.Windows.Forms.TrackBar
$fov.Location = New-Object System.Drawing.Point(15, 269)
$fov.Size = New-Object System.Drawing.Size(620, 45)
$fov.Minimum = 45
$fov.Maximum = 100
$fov.TickFrequency = 15
$fov.Value = [math]::Max(45, [math]::Min(100, [int]$settings.fieldOfView))
$controlsTab.Controls.Add($fov)
$controlsTab.Controls.Add((New-TextLabel -Text '60 degrees vertical is about 91 degrees horizontal at 16:9. Wider values reveal more of the scene.' -X 22 -Y 321 -Width 610 -Height 35 -Size 8.5 -Color $inkSoft))

$systemTab.Controls.Add((New-TextLabel -Text 'SAVE SAFETY' -X 22 -Y 22 -Width 150 -Height 20 -Size 9 -Color $olive -Style Bold))
$backupCheck = New-Object System.Windows.Forms.CheckBox
$backupCheck.Text = 'Create a backup when saves change'
$backupCheck.Location = New-Object System.Drawing.Point(22, 55)
$backupCheck.Size = New-Object System.Drawing.Size(280, 28)
$backupCheck.Checked = [bool]$settings.backupSaves
$backupCheck.Font = New-Font -Size 9.5
$systemTab.Controls.Add($backupCheck)

$systemTab.Controls.Add((New-TextLabel -Text 'Keep' -X 325 -Y 59 -Width 45 -Height 20 -Size 9 -Color $inkSoft))
$retention = New-Object System.Windows.Forms.NumericUpDown
$retention.Location = New-Object System.Drawing.Point(370, 55)
$retention.Size = New-Object System.Drawing.Size(65, 28)
$retention.Minimum = 1
$retention.Maximum = 50
$retention.Value = [math]::Max(1, [math]::Min(50, [int]$settings.backupRetention))
Style-Field $retention
$systemTab.Controls.Add($retention)
$systemTab.Controls.Add((New-TextLabel -Text 'snapshots' -X 445 -Y 59 -Width 90 -Height 20 -Size 9 -Color $inkSoft))

$pauseCheck = New-Object System.Windows.Forms.CheckBox
$pauseCheck.Text = 'Pause emulation when the game loses focus'
$pauseCheck.Location = New-Object System.Drawing.Point(22, 101)
$pauseCheck.Size = New-Object System.Drawing.Size(340, 28)
$pauseCheck.Checked = [bool]$settings.pauseWhenInactive
$pauseCheck.Font = New-Font -Size 9.5
$systemTab.Controls.Add($pauseCheck)
$systemTab.Controls.Add((New-TextLabel -Text 'Backups are content-aware: launching twice without a save change does not create duplicates.' -X 22 -Y 145 -Width 610 -Height 38 -Size 8.5 -Color $inkSoft))

$systemTab.Controls.Add((New-TextLabel -Text 'TOOLS' -X 22 -Y 205 -Width 130 -Height 20 -Size 9 -Color $olive -Style Bold))
$openSavesButton = New-UtilityButton -Text 'OPEN SAVES' -X 22 -Y 238 -Width 140
$systemTab.Controls.Add($openSavesButton)
$openRuntimeButton = New-UtilityButton -Text 'OPEN RUNTIME' -X 174 -Y 238 -Width 140
$systemTab.Controls.Add($openRuntimeButton)
$diagnosticsButton = New-UtilityButton -Text 'COPY DIAGNOSTICS' -X 326 -Y 238 -Width 155
$systemTab.Controls.Add($diagnosticsButton)
$resetButton = New-UtilityButton -Text 'RESET QUALITY' -X 493 -Y 238 -Width 140
$systemTab.Controls.Add($resetButton)
$systemTab.Controls.Add((New-TextLabel -Text 'Diagnostics copy version and file hashes without including ROM data.' -X 22 -Y 294 -Width 610 -Height 30 -Size 8.5 -Color $inkSoft))

$launchStatus = New-TextLabel -Text 'Ready to configure.' -X 40 -Y 655 -Width 430 -Height 42 -Size 9 -Color $inkSoft
$main.Controls.Add($launchStatus)

$launchButton = New-Object System.Windows.Forms.Button
$launchButton.Text = 'LAUNCH GOLDENEYE  >'
$launchButton.Location = New-Object System.Drawing.Point(493, 648)
$launchButton.Size = New-Object System.Drawing.Size(215, 50)
$launchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$launchButton.FlatAppearance.BorderSize = 0
$launchButton.BackColor = $red
$launchButton.ForeColor = [System.Drawing.Color]::White
$launchButton.Font = New-Font -Size 10.5 -Style Bold
$launchButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$main.Controls.Add($launchButton)
$form.AcceptButton = $launchButton

$footer = New-TextLabel -Text 'DESKTOPGOLDENEYE  /  1964GEPD  /  MOUSE INJECTOR 2.3  /  GLIDEN64' -X 40 -Y 726 -Width 670 -Height 20 -Size 7.5 -Color ([System.Drawing.Color]::FromArgb(126, 128, 118)) -Style Bold
$main.Controls.Add($footer)

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($vsyncCheck, 'Can reduce tearing, but may add input latency.')
$toolTip.SetToolTip($aaCombo, 'MSAA improves polygon edges without the blur introduced by FXAA.')
$toolTip.SetToolTip($anisotropyCombo, 'Improves textures viewed at an angle with little cost on modern GPUs.')
$toolTip.SetToolTip($texturePackCheck, 'Uses the bundled enhanced GoldenEye HUD texture cache.')
$toolTip.SetToolTip($accelerationCheck, 'Off is recommended for consistent muscle memory.')
$toolTip.SetToolTip($headRollCheck, 'Reduces GoldenEye camera roll for a steadier modern-FPS feel.')
$toolTip.SetToolTip($fov, '60 degrees vertical is approximately 91 degrees horizontal at 16:9.')
$toolTip.SetToolTip($backupCheck, 'Creates a new snapshot only when a save file has changed.')

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

$openSavesButton.Add_Click({
    $path = Join-Path $InstallRoot '1964\save'
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Start-Process -FilePath $path
})

$openRuntimeButton.Add_Click({
    $path = Join-Path $InstallRoot '1964'
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show($form, 'The quality runtime is not installed yet.', 'Runtime not found') | Out-Null
        return
    }
    Start-Process -FilePath $path
})

$diagnosticsButton.Add_Click({
    try {
        $diagnostics = Get-GoldenEyeDiagnostics -InstallRoot $InstallRoot
        [System.Windows.Forms.Clipboard]::SetText($diagnostics)
        $launchStatus.Text = 'Diagnostics copied to the clipboard.'
        $launchStatus.ForeColor = $success
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Diagnostics failed') | Out-Null
    }
})

$resetButton.Add_Click({
    $settings.displayMode = 'Fullscreen'
    $settings.fullscreenWidth = $screen.Width
    $settings.fullscreenHeight = $screen.Height
    $settings.windowedWidth = 1280
    $settings.windowedHeight = 720
    $displayCombo.SelectedItem = 'Fullscreen'
    & $setResolutionSelection
    $vsyncCheck.Checked = $false
    $aaCombo.SelectedIndex = 3
    $anisotropyCombo.SelectedIndex = 4
    $aspectCombo.SelectedIndex = 0
    $texturePackCheck.Checked = $true
    $fpsCheck.Checked = $false
    $controlsCombo.SelectedIndex = 0
    $sensitivity.Value = 20
    $invertCheck.Checked = $false
    $accelerationCheck.Checked = $false
    $headRollCheck.Checked = $true
    $fov.Value = 60
    $backupCheck.Checked = $true
    $retention.Value = 10
    $pauseCheck.Checked = $true
    $launchStatus.Text = 'Quality defaults restored. Launch to save and apply them.'
    $launchStatus.ForeColor = $success
})

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
        $next.antiAliasing = @('Off', 'FXAA', 'MSAA2', 'MSAA4', 'MSAA8')[$aaCombo.SelectedIndex]
        $next.anisotropy = @(0, 2, 4, 8, 16)[$anisotropyCombo.SelectedIndex]
        $next.aspectRatio = @('Widescreen', 'Original4x3', 'Stretch', 'Adjust')[$aspectCombo.SelectedIndex]
        $next.texturePack = $texturePackCheck.Checked
        $next.showFps = $fpsCheck.Checked
        $next.controlPreset = @('ModernFPS', 'Hybrid', 'ClassicInjector')[$controlsCombo.SelectedIndex]
        $next.mouseSensitivityPercent = $sensitivity.Value * 5
        $next.mouseAcceleration = $accelerationCheck.Checked
        $next.invertMouseY = $invertCheck.Checked
        $next.fieldOfView = $fov.Value
        $next.disableHeadRoll = $headRollCheck.Checked
        $next.pauseWhenInactive = $pauseCheck.Checked
        $next.backupSaves = $backupCheck.Checked
        $next.backupRetention = [int]$retention.Value

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
