[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PackageArchive,
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$archive = (Resolve-Path -LiteralPath $PackageArchive).Path
if (-not $OutputPath) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($archive)
    $OutputPath = Join-Path $repositoryRoot "dist\$baseName-Portable.exe"
}
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)

$workRoot = Join-Path $env:LOCALAPPDATA 'DesktopGoldenEye\portable-exe-build'
if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force }
New-Item -ItemType Directory -Path $workRoot | Out-Null
$payload = Join-Path $workRoot 'payload.zip'
Copy-Item -LiteralPath $archive -Destination $payload
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'packaging\windows\portable-bootstrap.ps1') -Destination $workRoot
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'packaging\windows\portable-launch.cmd') -Destination $workRoot

$localOutput = Join-Path $workRoot 'DesktopGoldenEye-Portable.exe'
$sed = Join-Path $workRoot 'DesktopGoldenEye.sed'
$sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$localOutput
FriendlyName=DesktopGoldenEye Portable
AppLaunched=cmd.exe /d /c portable-launch.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles

[Strings]
FILE0=portable-launch.cmd
FILE1=portable-bootstrap.ps1
FILE2=payload.zip

[SourceFiles]
SourceFiles0=$workRoot\

[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
"@
Set-Content -LiteralPath $sed -Value $sedContent -Encoding ASCII

$iexpress = Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\iexpress.exe') -ArgumentList @('/N', '/Q', $sed) -Wait -PassThru
if ($iexpress.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $localOutput -PathType Leaf)) {
    throw "IExpress failed to create the portable executable (exit code $($iexpress.ExitCode))."
}
New-Item -ItemType Directory -Path (Split-Path -Parent $OutputPath) -Force | Out-Null
Copy-Item -LiteralPath $localOutput -Destination $OutputPath -Force
$hash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash.ToUpperInvariant()
Write-Host "Packaged $OutputPath"
Write-Host "SHA-256 $hash"
