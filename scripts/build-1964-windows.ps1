[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [string]$InstallRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = $repositoryRoot

# Windows treats a WSL UNC checkout as case-sensitive. The 2002 source tree
# intentionally relies on Windows' case-insensitive include lookup, so stage
# only the build inputs on NTFS when this script is invoked through WSL.
if ($repositoryRoot.StartsWith('\\')) {
    $buildRoot = Join-Path $env:LOCALAPPDATA '1964QBranch\build-source'
    if (Test-Path -LiteralPath $buildRoot) {
        Remove-Item -LiteralPath $buildRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $buildRoot | Out-Null
    Get-ChildItem -LiteralPath $repositoryRoot -File | Where-Object { $_.Extension -in @('.c', '.h') } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $buildRoot
    }
    foreach ($directory in @('dynaRec', 'win32', 'zlib', 'build')) {
        Copy-Item -LiteralPath (Join-Path $repositoryRoot $directory) -Destination $buildRoot -Recurse
    }
}

$project = Join-Path $buildRoot 'build\windows\1964.vcxproj'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path -LiteralPath $vswhere -PathType Leaf)) {
    throw 'Visual Studio Installer vswhere.exe was not found. Install Visual Studio 2022 Build Tools with Desktop development with C++.'
}

$installation = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
if (-not $installation) {
    throw 'Visual Studio Build Tools with MSBuild were not found.'
}
$msbuild = Join-Path $installation 'MSBuild\Current\Bin\MSBuild.exe'
if (-not (Test-Path -LiteralPath $msbuild -PathType Leaf)) {
    throw "MSBuild was not found at '$msbuild'."
}

& $msbuild $project /m /restore /p:Configuration=$Configuration /p:Platform=Win32 /v:minimal
if ($LASTEXITCODE -ne 0) { throw "1964 $Configuration build failed with exit code $LASTEXITCODE." }

$builtExecutable = Join-Path $buildRoot "out\$Configuration\1964-qbranch.exe"
if (-not (Test-Path -LiteralPath $builtExecutable -PathType Leaf)) {
    throw "MSBuild succeeded but did not produce '$builtExecutable'."
}
$executable = Join-Path $repositoryRoot "out\$Configuration\1964-qbranch.exe"
if ($buildRoot -ne $repositoryRoot) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $executable) -Force | Out-Null
    Copy-Item -LiteralPath $builtExecutable -Destination $executable -Force
}
if ($InstallRoot) {
    $runtime = Join-Path $InstallRoot '1964'
    foreach ($relativePath in @('1964.exe', 'plugin\GLideN64.dll', 'plugin\Mouse_Injector.dll', 'plugin\AziAudio.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $runtime $relativePath) -PathType Leaf)) {
            throw "Install root is not a complete quality runtime; missing 1964\$relativePath"
        }
    }
    $installedExecutable = Join-Path $runtime '1964-qbranch.exe'
    Copy-Item -LiteralPath $executable -Destination $installedExecutable -Force
    Write-Host "Installed $installedExecutable"
}
Write-Host "Built $executable"
