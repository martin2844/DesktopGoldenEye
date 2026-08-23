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
        '1964.exe',
        'BUNDLE_README.txt',
        'source.tar.xz',
        'plugin\GLideN64.dll',
        'plugin\Mouse_Injector.dll',
        'plugin\AziAudio.dll'
    )
    foreach ($relativePath in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $runtime $relativePath) -PathType Leaf)) { return $false }
    }
    return $true
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
        Copy-Item -LiteralPath $PSCommandPath -Destination $destination -Force
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Test-GoldenEye.Runtime.ps1') -Destination $destination -Force
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'adapters') -Destination $destination -Recurse -Force
    }
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
        $width = 1920
        $height = 1080
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $width = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
            $height = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
        }
        catch {
            Write-Warning 'Could not query the primary display; using a 1920x1080 fullscreen profile.'
        }
        $glideTemplate = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'adapters\1964gepd\GLideN64-quality.ini.in') -Raw
        $glideConfig = $glideTemplate.Replace('@FULLSCREEN_WIDTH@', $width).Replace('@FULLSCREEN_HEIGHT@', $height)
        Set-Content -LiteralPath $glideProfile -Value $glideConfig -Encoding ASCII
    }
}

function Get-RomLaunchAlias {
    param([Parameter(Mandatory)]$RomInfo)

    $source = $RomInfo.Path
    if ((Split-Path -Leaf $source) -notmatch '\s') { return $source }
    $alias = Join-Path (Split-Path -Parent $source) ("GoldenEye007USA.$($RomInfo.Format)")
    if (Test-Path -LiteralPath $alias) {
        $aliasHash = (Get-FileHash -LiteralPath $alias -Algorithm SHA1).Hash.ToUpperInvariant()
        if ($aliasHash -ne $RomInfo.Sha1) { throw "ROM launch alias already exists with different content: $alias" }
        return $alias
    }

    Write-Host "Creating a no-space NTFS hard-link beside the ROM for 1964's legacy command-line parser..."
    try {
        New-Item -ItemType HardLink -Path $alias -Target $source | Out-Null
    }
    catch {
        throw "1964 cannot parse spaces in ROM filenames, and a hard-link alias could not be created. Rename the ROM without spaces or create '$alias' as a hard link. $($_.Exception.Message)"
    }
    return $alias
}

function Start-QualityRuntime {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$RomInfo,
        [switch]$Windowed,
        [switch]$Wait
    )

    if (-not (Test-QualityRuntime -InstallRoot $InstallRoot)) {
        throw "Quality runtime is not installed. Run Setup first."
    }
    Set-QualityProfile -InstallRoot $InstallRoot -RomInfo $RomInfo
    $romAlias = Get-RomLaunchAlias -RomInfo $RomInfo
    $romDirectory = Split-Path -Parent $romAlias
    if ($romDirectory -match '\s') {
        throw "1964's command-line parser cannot use a ROM directory containing spaces: '$romDirectory'. Move the ROM to a path such as D:\Roms."
    }

    $runtime = Join-Path $InstallRoot '1964'
    $arguments = @(
        '-r', $romDirectory,
        '-g', (Split-Path -Leaf $romAlias),
        '-v', 'GLideN64.dll',
        '-a', 'AziAudio.dll',
        '-c', 'Mouse_Injector.dll',
        '-o', '9'
    )
    if (-not $Windowed) { $arguments += '-f' }
    $process = Start-Process -FilePath (Join-Path $runtime '1964.exe') -WorkingDirectory $runtime -ArgumentList $arguments -PassThru
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
    [pscustomobject]@{ RuntimePath = $runtime; Rom = $rom; Release = $script:QualityRelease.Name }
}

function Start-GoldenEyeRuntime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Quality', 'Experimental')][string]$Runtime,
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)][string]$RomPath,
        [string]$ExperimentalExecutable,
        [switch]$Windowed,
        [switch]$Wait
    )
    $rom = Get-GoldenEyeRomInfo -RomPath $RomPath
    if ($Runtime -eq 'Quality') {
        return Start-QualityRuntime -InstallRoot $InstallRoot -RomInfo $rom -Windowed:$Windowed -Wait:$Wait
    }
    if (-not $ExperimentalExecutable) { throw 'Experimental runtime requires -ExperimentalExecutable pointing to ge007.exe.' }
    return Start-ExperimentalRuntime -Executable $ExperimentalExecutable -RomInfo $rom -Wait:$Wait
}

Export-ModuleMember -Function Get-GoldenEyeRomInfo, Install-GoldenEyeRuntime, Start-GoldenEyeRuntime
