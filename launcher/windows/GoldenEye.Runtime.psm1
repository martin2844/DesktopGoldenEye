Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:QualityRelease = [ordered]@{
    Name = '1964 GEPD Edition (No Discord Rich Presence)'
    Url = 'https://github.com/Graslu/1964GEPD/releases/download/latest/1964_GEPD_Edition_.No_DRP.zip'
    Sha1 = 'D7C7099A41E8AE3427EAE22D8F95796D9DFC44A8'
    Sha256 = 'DAD8CE4CBDDDCB8447CE59BF194AD0ACF4C237A45A566CFFF7D3A1310CCE6F6E'
}

$script:SupportedRoms = @{
    # The same US ROM in the three standard N64 byte orders.
    'ABE01E4AEB033B6C0836819F549C791B26CFDE83' = @{ Format = 'z64'; Magic = '80371240' }
    '7DD376E996D77D108316AC7CED087125C5674FA4' = @{ Format = 'v64'; Magic = '37804012' }
    '37BA02DE8BBCBC24F9BAAFB03E6F29A0B8C7A808' = @{ Format = 'n64'; Magic = '40123780' }
}

function Get-GoldenEyeRomInfo {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RomPath)

    $resolved = (Resolve-Path -LiteralPath $RomPath).Path
    $item = Get-Item -LiteralPath $resolved
    if ($item.Length -ne 12582912) {
        throw "Unsupported ROM size $($item.Length). Expected the 12 MiB US GoldenEye 007 ROM."
    }

    $stream = [System.IO.File]::OpenRead($resolved)
    try {
        $header = New-Object byte[] 4
        if ($stream.Read($header, 0, 4) -ne 4) { throw 'ROM is too short to contain an N64 header.' }
    }
    finally {
        $stream.Dispose()
    }

    $magic = -join ($header | ForEach-Object { $_.ToString('X2') })
    $sha1 = (Get-FileHash -LiteralPath $resolved -Algorithm SHA1).Hash.ToUpperInvariant()
    if (-not $script:SupportedRoms.ContainsKey($sha1)) {
        throw "Unsupported GoldenEye ROM (SHA-1 $sha1, magic $magic). This build requires the unmodified US release."
    }

    $known = $script:SupportedRoms[$sha1]
    if ($magic -ne $known.Magic) {
        throw "ROM byte-order marker $magic does not match its expected $($known.Format) format."
    }

    [pscustomobject]@{
        Path = $resolved
        Sha1 = $sha1
        CanonicalSha1 = 'ABE01E4AEB033B6C0836819F549C791B26CFDE83'
        Format = $known.Format
        Size = $item.Length
    }
}

function Test-QualityRuntime {
    param([Parameter(Mandatory)][string]$InstallRoot)
    $runtime = Join-Path $InstallRoot '1964'
    $required = @(
        'BUNDLE_README.txt',
        'source.tar.xz',
        'zlib.dll',
        'msvcr100.dll',
        'plugin\mouseinjector.ini',
        'plugin\GLideN64.dll',
        'plugin\Mouse_Injector.dll',
        'plugin\AziAudio.dll'
    )
    foreach ($relativePath in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $runtime $relativePath) -PathType Leaf)) { return $false }
    }
    return (
        (Test-Path -LiteralPath (Join-Path $runtime 'DesktopGoldenEye.exe') -PathType Leaf) -or
        (Test-Path -LiteralPath (Join-Path $runtime '1964-qbranch.exe') -PathType Leaf) -or
        (Test-Path -LiteralPath (Join-Path $runtime '1964.exe') -PathType Leaf)
    )
}

function Get-QualityRuntimeExecutable {
    param([Parameter(Mandatory)][string]$InstallRoot)

    $runtime = Join-Path $InstallRoot '1964'
    $desktopGoldenEye = Join-Path $runtime 'DesktopGoldenEye.exe'
    if (Test-Path -LiteralPath $desktopGoldenEye -PathType Leaf) { return $desktopGoldenEye }
    $legacyQBranch = Join-Path $runtime '1964-qbranch.exe'
    if (Test-Path -LiteralPath $legacyQBranch -PathType Leaf) { return $legacyQBranch }
    return (Join-Path $runtime '1964.exe')
}

function Install-QualityRuntime {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [string]$BundlePath
    )

    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
    if (Test-QualityRuntime -InstallRoot $InstallRoot) {
        return (Join-Path $InstallRoot '1964')
    }

    $downloads = Join-Path $InstallRoot 'downloads'
    New-Item -ItemType Directory -Path $downloads -Force | Out-Null
    if (-not $BundlePath) {
        $BundlePath = Join-Path $downloads '1964_GEPD_Edition_No_DRP.zip'
    }
    if (-not (Test-Path -LiteralPath $BundlePath -PathType Leaf)) {
        Write-Host "Downloading $($script:QualityRelease.Name) from its official GitHub release..."
        Invoke-WebRequest -UseBasicParsing -Uri $script:QualityRelease.Url -OutFile $BundlePath
    }

    $sha1 = (Get-FileHash -LiteralPath $BundlePath -Algorithm SHA1).Hash.ToUpperInvariant()
    $sha256 = (Get-FileHash -LiteralPath $BundlePath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($sha1 -ne $script:QualityRelease.Sha1 -or $sha256 -ne $script:QualityRelease.Sha256) {
        throw "1964GEPD bundle hash mismatch. Refusing to extract '$BundlePath'."
    }

    $staging = Join-Path $InstallRoot ('.staging-1964gepd-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $staging | Out-Null
    try {
        Expand-Archive -LiteralPath $BundlePath -DestinationPath $staging
        $expanded = Join-Path $staging '1964'
        if (-not (Test-Path -LiteralPath (Join-Path $expanded '1964.exe') -PathType Leaf)) {
            throw 'The verified archive did not contain the expected 1964/1964.exe layout.'
        }
        Move-Item -LiteralPath $expanded -Destination (Join-Path $InstallRoot '1964')
    }
    finally {
        if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
    }

    if (-not (Test-QualityRuntime -InstallRoot $InstallRoot)) {
        throw '1964GEPD installation is incomplete after extraction.'
    }
    return (Join-Path $InstallRoot '1964')
}

function Copy-LauncherFiles {
    param([Parameter(Mandatory)][string]$InstallRoot)

    $destination = Join-Path $InstallRoot 'launcher'
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $sourceRoot = [System.IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
    $destinationRoot = [System.IO.Path]::GetFullPath($destination).TrimEnd('\')
    if ($sourceRoot -ne $destinationRoot) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'GoldenEye.ps1') -Destination $destination -Force
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'GoldenEye.Launcher.ps1') -Destination $destination -Force
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'DesktopGoldenEye.cmd') -Destination $destination -Force
        Copy-Item -LiteralPath $PSCommandPath -Destination $destination -Force
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Test-GoldenEye.Runtime.ps1') -Destination $destination -Force
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'adapters') -Destination $destination -Recurse -Force
    }
}

function Get-PrimaryDisplaySize {
    $width = 1920
    $height = 1080
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $width = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
        $height = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    }
    catch {
        Write-Warning 'Could not query the primary display; using 1920x1080.'
    }
    [pscustomobject]@{ Width = $width; Height = $height }
}

function Get-GoldenEyeLauncherSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [string]$RomPath
    )

    $display = Get-PrimaryDisplaySize
    $settings = [ordered]@{
        schemaVersion = 3
        romPath = $RomPath
        preferredRuntime = 'Quality'
        displayMode = 'Fullscreen'
        fullscreenWidth = $display.Width
        fullscreenHeight = $display.Height
        windowedWidth = 1280
        windowedHeight = 720
        verticalSync = $false
        antiAliasing = 'MSAA4'
        anisotropy = 16
        aspectRatio = 'Widescreen'
        texturePack = $true
        showFps = $false
        controlPreset = 'ModernFPS'
        mouseSensitivityPercent = 100
        mouseAcceleration = $false
        invertMouseY = $false
        fieldOfView = 60
        disableHeadRoll = $true
        pauseWhenInactive = $true
        backupSaves = $true
        backupRetention = 10
    }

    $statePath = Join-Path $InstallRoot 'launcher-state.json'
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $saved = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        foreach ($name in @($settings.Keys)) {
            $property = $saved.PSObject.Properties[$name]
            if ($null -ne $property -and $null -ne $property.Value) {
                $settings[$name] = $property.Value
            }
        }
    }
    if ($RomPath) { $settings.romPath = $RomPath }
    $settings.schemaVersion = 3
    [pscustomobject]$settings
}

function Save-GoldenEyeLauncherSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Settings
    )

    if (-not $Settings.romPath) { throw 'Choose your GoldenEye 007 US ROM before saving settings.' }
    $rom = Get-GoldenEyeRomInfo -RomPath $Settings.romPath
    if ($Settings.displayMode -notin @('Fullscreen', 'Borderless', 'Windowed')) {
        throw "Unsupported display mode '$($Settings.displayMode)'."
    }
    if ($Settings.controlPreset -notin @('ModernFPS', 'Hybrid', 'ClassicInjector')) {
        throw "Unsupported control preset '$($Settings.controlPreset)'."
    }
    if ($Settings.antiAliasing -notin @('Off', 'FXAA', 'MSAA2', 'MSAA4', 'MSAA8')) {
        throw "Unsupported anti-aliasing mode '$($Settings.antiAliasing)'."
    }
    if ([int]$Settings.anisotropy -notin @(0, 2, 4, 8, 16)) {
        throw "Unsupported anisotropic filtering level '$($Settings.anisotropy)'."
    }
    if ($Settings.aspectRatio -notin @('Widescreen', 'Original4x3', 'Stretch', 'Adjust')) {
        throw "Unsupported aspect ratio '$($Settings.aspectRatio)'."
    }
    foreach ($dimension in @('fullscreenWidth', 'fullscreenHeight', 'windowedWidth', 'windowedHeight')) {
        if ([int]$Settings.$dimension -lt 320 -or [int]$Settings.$dimension -gt 16384) {
            throw "Display dimension '$dimension' is outside the supported range."
        }
    }
    if ([int]$Settings.mouseSensitivityPercent -lt 25 -or [int]$Settings.mouseSensitivityPercent -gt 500) {
        throw 'Mouse sensitivity must be between 25% and 500%.'
    }
    if ([int]$Settings.fieldOfView -lt 45 -or [int]$Settings.fieldOfView -gt 120) {
        throw 'Vertical field of view must be between 45 and 120 degrees.'
    }
    if ([int]$Settings.backupRetention -lt 1 -or [int]$Settings.backupRetention -gt 50) {
        throw 'Save-backup retention must be between 1 and 50 snapshots.'
    }

    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
    $normalized = [ordered]@{
        schemaVersion = 3
        romPath = $rom.Path
        preferredRuntime = 'Quality'
        displayMode = [string]$Settings.displayMode
        fullscreenWidth = [int]$Settings.fullscreenWidth
        fullscreenHeight = [int]$Settings.fullscreenHeight
        windowedWidth = [int]$Settings.windowedWidth
        windowedHeight = [int]$Settings.windowedHeight
        verticalSync = [bool]$Settings.verticalSync
        antiAliasing = [string]$Settings.antiAliasing
        anisotropy = [int]$Settings.anisotropy
        aspectRatio = [string]$Settings.aspectRatio
        texturePack = [bool]$Settings.texturePack
        showFps = [bool]$Settings.showFps
        controlPreset = [string]$Settings.controlPreset
        mouseSensitivityPercent = [int]$Settings.mouseSensitivityPercent
        mouseAcceleration = [bool]$Settings.mouseAcceleration
        invertMouseY = [bool]$Settings.invertMouseY
        fieldOfView = [int]$Settings.fieldOfView
        disableHeadRoll = [bool]$Settings.disableHeadRoll
        pauseWhenInactive = [bool]$Settings.pauseWhenInactive
        backupSaves = [bool]$Settings.backupSaves
        backupRetention = [int]$Settings.backupRetention
    }
    $normalized | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $InstallRoot 'launcher-state.json') -Encoding UTF8
    [pscustomobject]$normalized
}

function Set-ConfigEntry {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Separator,
        [switch]$AppendIfMissing
    )
    $pattern = '(?m)^' + [regex]::Escape($Key) + '.*$'
    if (-not [regex]::IsMatch($Content, $pattern)) {
        if ($AppendIfMissing) {
            return $Content.TrimEnd() + [Environment]::NewLine + $Key + $Separator + $Value + [Environment]::NewLine
        }
        throw "Configuration entry '$Key' was not found."
    }
    [regex]::Replace($Content, $pattern, ($Key + $Separator + $Value), 1)
}

function Set-MouseInjectorProfile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Settings
    )

    $values = @(Get-Content -LiteralPath $Path | ForEach-Object { [int]$_ })
    if ($values.Count -ne 192) { throw "Mouse Injector profile has $($values.Count) lines; expected 192." }

    $values[144] = 1
    $values[145] = [math]::Round([int]$Settings.mouseSensitivityPercent / 5)
    $values[146] = if ([bool]$Settings.mouseAcceleration) { 1 } else { 0 }
    $values[148] = if ([bool]$Settings.invertMouseY) { 1 } else { 0 }
    $values[149] = 0

    switch ([string]$Settings.controlPreset) {
        'ModernFPS' {
            $values[147] = 0
            $values[150] = 0
            $values[187] = 1
        }
        'Hybrid' {
            $values[147] = 3
            $values[150] = 0
            $values[187] = 0
        }
        'ClassicInjector' {
            $values[147] = 3
            $values[150] = 1
            $values[187] = 0
        }
    }

    $values[184] = [int]$Settings.fieldOfView
    $values[185] = 16
    $values[186] = 9
    $values[188] = 0
    $values[189] = 1
    $values[190] = 1
    $values[191] = 52
    Set-Content -LiteralPath $Path -Value $values -Encoding ASCII
}

function Set-QualityProfile {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$RomInfo,
        [switch]$Replace
    )

    $runtime = Join-Path $InstallRoot '1964'
    $configPath = Join-Path $runtime '1964.cfg'
    if ($Replace -or -not (Test-Path -LiteralPath $configPath)) {
        if ($Replace -and (Test-Path -LiteralPath $configPath) -and -not (Test-Path -LiteralPath "$configPath.user-backup")) {
            Copy-Item -LiteralPath $configPath -Destination "$configPath.user-backup"
        }
        $template = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'adapters\1964gepd\1964-quality.cfg.in') -Raw
        $romDirectory = Split-Path -Parent $RomInfo.Path
        $profile = $template.Replace('@ROM_DIRECTORY@', $romDirectory).Replace('@RUNTIME_DIRECTORY@', $runtime)
        Set-Content -LiteralPath $configPath -Value $profile -Encoding ASCII
    }

    $glideProfile = Join-Path $runtime 'plugin\GLideN64.ini'
    if ($Replace -or -not (Test-Path -LiteralPath $glideProfile)) {
        if ($Replace -and (Test-Path -LiteralPath $glideProfile) -and -not (Test-Path -LiteralPath "$glideProfile.user-backup")) {
            Copy-Item -LiteralPath $glideProfile -Destination "$glideProfile.user-backup"
        }
        $display = Get-PrimaryDisplaySize
        $glideTemplate = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'adapters\1964gepd\GLideN64-quality.ini.in') -Raw
        $glideConfig = $glideTemplate.Replace('@FULLSCREEN_WIDTH@', $display.Width).Replace('@FULLSCREEN_HEIGHT@', $display.Height)
        Set-Content -LiteralPath $glideProfile -Value $glideConfig -Encoding ASCII
    }
}

function Set-GoldenEyeRuntimeSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Settings
    )

    $rom = Get-GoldenEyeRomInfo -RomPath $Settings.romPath
    Set-QualityProfile -InstallRoot $InstallRoot -RomInfo $rom

    $runtimeConfigPath = Join-Path $InstallRoot '1964\1964.cfg'
    $runtimeConfig = Get-Content -LiteralPath $runtimeConfigPath -Raw
    $borderless = if ($Settings.displayMode -eq 'Borderless') { '1' } else { '0' }
    $runtimeConfig = Set-ConfigEntry -Content $runtimeConfig -Key 'BorderlessFullscreen' -Value $borderless -Separator ' '
    $runtimeConfig = Set-ConfigEntry -Content $runtimeConfig -Key 'ClientWindowWidth' -Value ([string][int]$Settings.windowedWidth) -Separator ' '
    $runtimeConfig = Set-ConfigEntry -Content $runtimeConfig -Key 'ClientWindowHeight' -Value ([string][int]$Settings.windowedHeight) -Separator ' '
    $runtimeConfig = Set-ConfigEntry -Content $runtimeConfig -Key 'GEDisableHeadRoll' -Value $(if ([bool]$Settings.disableHeadRoll) { '1' } else { '0' }) -Separator ' '
    $runtimeConfig = Set-ConfigEntry -Content $runtimeConfig -Key 'PauseWhenInactive' -Value $(if ([bool]$Settings.pauseWhenInactive) { '1' } else { '0' }) -Separator ' '
    Set-Content -LiteralPath $runtimeConfigPath -Value $runtimeConfig -Encoding ASCII

    $videoConfigPath = Join-Path $InstallRoot '1964\plugin\GLideN64.ini'
    $videoConfig = Get-Content -LiteralPath $videoConfigPath -Raw
    $multisampling = switch ([string]$Settings.antiAliasing) {
        'MSAA2' { 2 }
        'MSAA4' { 4 }
        'MSAA8' { 8 }
        default { 0 }
    }
    $fxaa = if ($Settings.antiAliasing -eq 'FXAA') { 1 } else { 0 }
    $aspect = @{
        Stretch = 0
        Original4x3 = 1
        Widescreen = 2
        Adjust = 3
    }[[string]$Settings.aspectRatio]
    $entries = [ordered]@{
        'video\fullscreenWidth' = [int]$Settings.fullscreenWidth
        'video\fullscreenHeight' = [int]$Settings.fullscreenHeight
        'video\windowedWidth' = [int]$Settings.windowedWidth
        'video\windowedHeight' = [int]$Settings.windowedHeight
        'video\verticalSync' = $(if ([bool]$Settings.verticalSync) { 1 } else { 0 })
        'video\multisampling' = $multisampling
        'video\fxaa' = $fxaa
        'texture\maxAnisotropy' = [int]$Settings.anisotropy
        'frameBufferEmulation\aspect' = $aspect
        'textureFilter\txHiresEnable' = $(if ([bool]$Settings.texturePack) { 1 } else { 0 })
        'onScreenDisplay\showFPS' = $(if ([bool]$Settings.showFps) { 1 } else { 0 })
    }
    foreach ($entry in $entries.GetEnumerator()) {
        $videoConfig = Set-ConfigEntry -Content $videoConfig -Key $entry.Key -Value ([string]$entry.Value) -Separator '=' -AppendIfMissing
    }
    Set-Content -LiteralPath $videoConfigPath -Value $videoConfig -Encoding ASCII

    Set-MouseInjectorProfile -Path (Join-Path $InstallRoot '1964\plugin\mouseinjector.ini') -Settings $Settings
}

function Backup-GoldenEyeSaves {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [int]$Retention = 10
    )

    $saveDirectory = Join-Path $InstallRoot '1964\save'
    if (-not (Test-Path -LiteralPath $saveDirectory -PathType Container)) { return $null }

    $saveFiles = @(Get-ChildItem -LiteralPath $saveDirectory -File | Where-Object {
        $_.Extension -match '^\.(eep|sra|fla|mpk|m\d+|sav|state)$'
    } | Sort-Object Name)
    if ($saveFiles.Count -eq 0) { return $null }

    $fileRecords = @($saveFiles | ForEach-Object {
        [ordered]@{
            name = $_.Name
            length = $_.Length
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        }
    })
    $signature = ($fileRecords | ForEach-Object { "$($_.name):$($_.length):$($_.sha256)" }) -join '|'

    $backupRoot = Join-Path $InstallRoot 'save-backups'
    $previous = @(Get-ChildItem -LiteralPath $backupRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1)
    if ($previous.Count -gt 0) {
        $previousManifest = Join-Path $previous[0].FullName 'manifest.json'
        if (Test-Path -LiteralPath $previousManifest -PathType Leaf) {
            try {
                $previousData = Get-Content -LiteralPath $previousManifest -Raw | ConvertFrom-Json
                if ($previousData.signature -eq $signature) { return $previous[0].FullName }
            }
            catch {
                Write-Warning "Ignoring unreadable save-backup manifest '$previousManifest'."
            }
        }
    }

    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $snapshot = Join-Path $backupRoot ([DateTime]::Now.ToString('yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $snapshot | Out-Null
    foreach ($file in $saveFiles) {
        Copy-Item -LiteralPath $file.FullName -Destination $snapshot
    }
    [ordered]@{
        schemaVersion = 1
        createdAt = [DateTime]::UtcNow.ToString('o')
        signature = $signature
        files = $fileRecords
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $snapshot 'manifest.json') -Encoding UTF8

    @(Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -Skip $Retention) | ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
    return $snapshot
}

function Get-GoldenEyeDiagnostics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$InstallRoot)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('DesktopGoldenEye diagnostics')
    $lines.Add("Generated: $([DateTime]::UtcNow.ToString('o'))")
    $lines.Add("Windows: $([Environment]::OSVersion.VersionString)")
    $lines.Add("PowerShell: $($PSVersionTable.PSVersion)")
    $lines.Add("Install root: $InstallRoot")
    $lines.Add("Runtime complete: $(Test-QualityRuntime -InstallRoot $InstallRoot)")
    $selectedExecutable = Get-QualityRuntimeExecutable -InstallRoot $InstallRoot
    $lines.Add("Selected core: $(Split-Path -Leaf $selectedExecutable)")

    $diagnosticFiles = @('1964\1964.exe', '1964\plugin\GLideN64.dll', '1964\plugin\Mouse_Injector.dll', '1964\plugin\AziAudio.dll')
    if (Test-Path -LiteralPath (Join-Path $InstallRoot '1964\DesktopGoldenEye.exe') -PathType Leaf) {
        $diagnosticFiles = @('1964\DesktopGoldenEye.exe') + $diagnosticFiles
    }
    elseif (Test-Path -LiteralPath (Join-Path $InstallRoot '1964\1964-qbranch.exe') -PathType Leaf) {
        $diagnosticFiles = @('1964\1964-qbranch.exe') + $diagnosticFiles
    }
    foreach ($relativePath in $diagnosticFiles) {
        $path = Join-Path $InstallRoot $relativePath
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
            $lines.Add("$relativePath SHA-256 $hash")
        }
        else {
            $lines.Add("$relativePath MISSING")
        }
    }

    $statePath = Join-Path $InstallRoot 'launcher-state.json'
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $state = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot
        $lines.Add("Settings schema: $($state.schemaVersion)")
        $lines.Add("Display: $($state.displayMode) $($state.fullscreenWidth)x$($state.fullscreenHeight)")
        $lines.Add("Graphics: $($state.antiAliasing), $($state.anisotropy)x AF, $($state.aspectRatio), texture pack $($state.texturePack)")
        $lines.Add("Controls: $($state.controlPreset), sensitivity $($state.mouseSensitivityPercent)%, FOV $($state.fieldOfView)")
        if ($state.romPath -and (Test-Path -LiteralPath $state.romPath -PathType Leaf)) {
            $rom = Get-GoldenEyeRomInfo -RomPath $state.romPath
            $lines.Add("ROM: verified $($rom.Format), SHA-1 $($rom.Sha1)")
        }
    }
    return ($lines -join [Environment]::NewLine)
}

function Get-RomLaunchAlias {
    param(
        [Parameter(Mandatory)]$RomInfo,
        [string]$AliasDirectory
    )

    $source = $RomInfo.Path
    $sourceName = Split-Path -Leaf $source
    $expectedExtension = ".$($RomInfo.Format)"
    if (-not $AliasDirectory -and $sourceName -notmatch '\s' -and [System.IO.Path]::GetExtension($sourceName) -ieq $expectedExtension) { return $source }
    $aliasRoot = if ($AliasDirectory) { $AliasDirectory } else { Split-Path -Parent $source }
    New-Item -ItemType Directory -Path $aliasRoot -Force | Out-Null
    $alias = Join-Path $aliasRoot ("GoldenEye007USA.$($RomInfo.Format)")
    if (Test-Path -LiteralPath $alias) {
        $aliasHash = (Get-FileHash -LiteralPath $alias -Algorithm SHA1).Hash.ToUpperInvariant()
        if ($aliasHash -ne $RomInfo.Sha1) { throw "ROM launch alias already exists with different content: $alias" }
        return $alias
    }

    Write-Host 'Preparing a byte-order-correct local ROM launch alias...'
    try {
        New-Item -ItemType HardLink -Path $alias -Target $source | Out-Null
    }
    catch {
        try {
            Copy-Item -LiteralPath $source -Destination $alias
        }
        catch {
            if (Test-Path -LiteralPath $alias) { Remove-Item -LiteralPath $alias -Force }
            throw "Could not prepare the local ROM launch alias '$alias'. $($_.Exception.Message)"
        }
    }
    return $alias
}

function Initialize-QualityWindowInputCapture {
    param([Parameter(Mandatory)][System.Diagnostics.Process]$Process)

    if (-not ('GoldenEyeWindowCapture' -as [type])) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class GoldenEyeWindowCapture
{
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [DllImport("user32.dll")]
    public static extern bool GetClientRect(IntPtr window, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr window, ref POINT point);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr window);
}
'@
    }

    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        if ($Process.HasExited) { throw '1964 exited before its game window was ready.' }
        $Process.Refresh()
        if ($Process.MainWindowHandle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)

    $window = $Process.MainWindowHandle
    if ($window -eq [IntPtr]::Zero) { throw '1964 did not create a game window within 10 seconds.' }
    try { [void]$Process.WaitForInputIdle(5000) } catch { }
    $Process.Refresh()
    $window = $Process.MainWindowHandle

    $client = New-Object GoldenEyeWindowCapture+RECT
    if (-not [GoldenEyeWindowCapture]::GetClientRect($window, [ref]$client)) {
        throw 'Could not read the 1964 client area for windowed mouse capture.'
    }

    $center = New-Object GoldenEyeWindowCapture+POINT
    $center.X = [math]::Floor(($client.Right - $client.Left) / 2)
    $center.Y = [math]::Floor(($client.Bottom - $client.Top) / 2)
    if (-not [GoldenEyeWindowCapture]::ClientToScreen($window, [ref]$center)) {
        throw 'Could not translate the 1964 client center for windowed mouse capture.'
    }

    [void][GoldenEyeWindowCapture]::SetForegroundWindow($window)
    if (-not [GoldenEyeWindowCapture]::SetCursorPos($center.X, $center.Y)) {
        throw 'Could not center the pointer inside the 1964 game window.'
    }

    # Mouse Injector checks focus every 500 ms and records the current pointer
    # location as its warp target. Keep the pointer centered through that poll.
    Start-Sleep -Milliseconds 650
    [void][GoldenEyeWindowCapture]::SetCursorPos($center.X, $center.Y)
}

function Get-QualityRuntimeArguments {
    param(
        [Parameter(Mandatory)][string]$RomDirectory,
        [Parameter(Mandatory)][string]$RomName,
        [Parameter(Mandatory)][bool]$UsingForkedCore,
        [switch]$Fullscreen
    )

    if ($UsingForkedCore) {
        $arguments = '-r "{0}" -g "{1}" -v GLideN64.dll -a AziAudio.dll -c Mouse_Injector.dll -o 9' -f $RomDirectory, $RomName
    }
    else {
        if ($RomDirectory -match '\s' -or $RomName -match '\s') {
            throw 'The released 1964GEPD command-line parser requires a space-free ROM directory and launch alias.'
        }
        $arguments = '-r {0} -g {1} -v GLideN64.dll -a AziAudio.dll -c Mouse_Injector.dll -o 9' -f $RomDirectory, $RomName
    }
    if ($Fullscreen) { $arguments += ' -f' }
    return $arguments
}

function Start-QualityRuntime {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$RomInfo,
        $Settings,
        [switch]$Windowed,
        [switch]$Wait
    )

    if (-not (Test-QualityRuntime -InstallRoot $InstallRoot)) {
        throw "Quality runtime is not installed. Run Setup first."
    }
    if ($null -eq $Settings) {
        $Settings = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -RomPath $RomInfo.Path
    }
    if ($Windowed) { $Settings.displayMode = 'Windowed' }
    Set-GoldenEyeRuntimeSettings -InstallRoot $InstallRoot -Settings $Settings
    $runtimeExecutable = (Resolve-Path -LiteralPath (Get-QualityRuntimeExecutable -InstallRoot $InstallRoot)).Path
    $usingForkedCore = (Split-Path -Leaf $runtimeExecutable) -in @('DesktopGoldenEye.exe', '1964-qbranch.exe')

    $runtime = Join-Path $InstallRoot '1964'
    $romAlias = if ($usingForkedCore) {
        Get-RomLaunchAlias -RomInfo $RomInfo
    }
    else {
        Get-RomLaunchAlias -RomInfo $RomInfo -AliasDirectory (Join-Path $runtime 'roms')
    }
    $romDirectory = if ($usingForkedCore) { Split-Path -Parent $romAlias } else { 'roms' }
    # The released 1964GEPD parser needs unquoted, space-free values. Its local
    # runtime alias and Get-QualityRuntimeArguments enforce that contract.
    $arguments = Get-QualityRuntimeArguments -RomDirectory $romDirectory -RomName (Split-Path -Leaf $romAlias) -UsingForkedCore $usingForkedCore -Fullscreen:($Settings.displayMode -ne 'Windowed')
    $runtimeName = [System.IO.Path]::GetFileNameWithoutExtension($runtimeExecutable)
    $runtimeIdentity = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($runtimeExecutable)).TrimEnd('=').Replace('/', '_').Replace('+', '-')
    $launchMutex = New-Object System.Threading.Mutex($false, "Local\DesktopGoldenEyeRuntime-$runtimeIdentity")
    $hasLaunchMutex = $false
    try {
        $hasLaunchMutex = $launchMutex.WaitOne(0)
        if (-not $hasLaunchMutex) { throw 'Another DesktopGoldenEye launcher is starting this runtime. Try again in a moment.' }
        $alreadyRunning = @(Get-Process -Name $runtimeName -ErrorAction SilentlyContinue | Where-Object {
            try { $_.Path -and $_.Path.Equals($runtimeExecutable, [System.StringComparison]::OrdinalIgnoreCase) }
            catch { $false }
        })
        if ($alreadyRunning.Count -gt 0) {
            throw 'GoldenEye is already running from this DesktopGoldenEye installation. Close it before starting another session.'
        }
        if ([bool]$Settings.backupSaves) {
            [void](Backup-GoldenEyeSaves -InstallRoot $InstallRoot -Retention ([int]$Settings.backupRetention))
        }
        $process = Start-Process -FilePath $runtimeExecutable -WorkingDirectory $runtime -ArgumentList $arguments -PassThru
    }
    finally {
        if ($hasLaunchMutex) { $launchMutex.ReleaseMutex() }
        $launchMutex.Dispose()
    }
    if ($Settings.displayMode -eq 'Windowed') {
        Initialize-QualityWindowInputCapture -Process $process
    }
    if ($Wait) { $process.WaitForExit() }
    return $process
}

function Start-ExperimentalRuntime {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)]$RomInfo,
        [switch]$Wait
    )
    $exe = (Resolve-Path -LiteralPath $Executable).Path
    $oldRom = $env:MGB64_ROM
    try {
        $env:MGB64_ROM = $RomInfo.Path
        $process = Start-Process -FilePath $exe -WorkingDirectory (Split-Path -Parent $exe) -PassThru
        if ($Wait) { $process.WaitForExit() }
        return $process
    }
    finally {
        $env:MGB64_ROM = $oldRom
    }
}

function Install-GoldenEyeRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$RomPath,
        [string]$BundlePath
    )
    $rom = Get-GoldenEyeRomInfo -RomPath $RomPath
    $runtime = Install-QualityRuntime -InstallRoot $InstallRoot -BundlePath $BundlePath
    Copy-LauncherFiles -InstallRoot $InstallRoot
    Set-QualityProfile -InstallRoot $InstallRoot -RomInfo $rom -Replace
    $settings = Get-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -RomPath $rom.Path
    $settings = Save-GoldenEyeLauncherSettings -InstallRoot $InstallRoot -Settings $settings
    Set-GoldenEyeRuntimeSettings -InstallRoot $InstallRoot -Settings $settings
    [pscustomobject]@{ RuntimePath = $runtime; Rom = $rom; Release = $script:QualityRelease.Name }
}

function Start-GoldenEyeRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Quality', 'Experimental')][string]$Runtime,
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$RomPath,
        [string]$ExperimentalExecutable,
        $Settings,
        [switch]$Windowed,
        [switch]$Wait
    )
    $rom = Get-GoldenEyeRomInfo -RomPath $RomPath
    if ($Runtime -eq 'Quality') {
        return Start-QualityRuntime -InstallRoot $InstallRoot -RomInfo $rom -Settings $Settings -Windowed:$Windowed -Wait:$Wait
    }
    if (-not $ExperimentalExecutable) { throw 'Experimental runtime requires -ExperimentalExecutable pointing to ge007.exe.' }
    return Start-ExperimentalRuntime -Executable $ExperimentalExecutable -RomInfo $rom -Wait:$Wait
}

Export-ModuleMember -Function Get-GoldenEyeRomInfo, Get-GoldenEyeLauncherSettings, Save-GoldenEyeLauncherSettings, Set-GoldenEyeRuntimeSettings, Backup-GoldenEyeSaves, Get-GoldenEyeDiagnostics, Get-QualityRuntimeExecutable, Get-QualityRuntimeArguments, Install-GoldenEyeRuntime, Start-GoldenEyeRuntime
