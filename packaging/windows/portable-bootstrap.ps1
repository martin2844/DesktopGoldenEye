Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$payload = Join-Path $PSScriptRoot 'payload.zip'
if (-not (Test-Path -LiteralPath $payload -PathType Leaf)) {
    throw 'DesktopGoldenEye portable payload is missing.'
}

$manifestEntry = [System.IO.Compression.ZipFile]::OpenRead($payload)
try {
    $entry = $manifestEntry.Entries | Where-Object { $_.FullName -match '(^|[\\/])release-manifest\.json$' } | Select-Object -First 1
    if (-not $entry) { throw 'Portable payload has no release manifest.' }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json }
    finally { $reader.Dispose() }
}
finally {
    $manifestEntry.Dispose()
}
if ($manifest.product -ne 'DesktopGoldenEye' -or $manifest.romIncluded -ne $false) {
    throw 'Portable payload manifest is invalid.'
}
$payloadId = "$($manifest.version)|$($manifest.sourceRevision)"

$cacheParent = Join-Path $env:LOCALAPPDATA 'DesktopGoldenEye'
$installRoot = Join-Path $cacheParent 'Portable'
$marker = Join-Path $installRoot '.payload-id'
$mutex = New-Object System.Threading.Mutex($false, 'Local\DesktopGoldenEyePortableBootstrap')
$hasMutex = $false
try {
    $hasMutex = $mutex.WaitOne([TimeSpan]::FromMinutes(3))
    if (-not $hasMutex) { throw 'Another DesktopGoldenEye portable launch is still preparing the runtime.' }

    $installedId = if (Test-Path -LiteralPath $marker -PathType Leaf) {
        (Get-Content -LiteralPath $marker -Raw).Trim()
    } else { '' }
    if ($installedId -ne $payloadId) {
        New-Item -ItemType Directory -Path $cacheParent -Force | Out-Null
        $staging = Join-Path $cacheParent ('.portable-staging-' + [guid]::NewGuid().ToString('N'))
        $backup = Join-Path $cacheParent ('.portable-backup-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $staging | Out-Null
        try {
            Expand-Archive -LiteralPath $payload -DestinationPath $staging
            $candidate = @(Get-ChildItem -LiteralPath $staging -Directory)
            if ($candidate.Count -ne 1) { throw 'Portable payload must contain exactly one product directory.' }
            $candidateRoot = $candidate[0].FullName
            foreach ($required in @('DesktopGoldenEye.cmd', 'release-manifest.json', '1964\1964.exe', 'launcher\GoldenEye.ps1')) {
                if (-not (Test-Path -LiteralPath (Join-Path $candidateRoot $required) -PathType Leaf)) {
                    throw "Portable payload is missing $required"
                }
            }

            if (Test-Path -LiteralPath $installRoot -PathType Container) {
                $oldState = Join-Path $installRoot 'launcher-state.json'
                if (Test-Path -LiteralPath $oldState -PathType Leaf) {
                    Copy-Item -LiteralPath $oldState -Destination $candidateRoot -Force
                }
                $oldSaves = Join-Path $installRoot '1964\save'
                $newSaves = Join-Path $candidateRoot '1964\save'
                if (Test-Path -LiteralPath $oldSaves -PathType Container) {
                    Get-ChildItem -LiteralPath $oldSaves -Force | ForEach-Object {
                        Copy-Item -LiteralPath $_.FullName -Destination $newSaves -Recurse -Force
                    }
                }
                $oldBackups = Join-Path $installRoot 'save-backups'
                if (Test-Path -LiteralPath $oldBackups -PathType Container) {
                    Copy-Item -LiteralPath $oldBackups -Destination (Join-Path $candidateRoot 'save-backups') -Recurse
                }
                Move-Item -LiteralPath $installRoot -Destination $backup
            }

            Move-Item -LiteralPath $candidateRoot -Destination $installRoot
            Set-Content -LiteralPath $marker -Value $payloadId -Encoding UTF8
            if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
        }
        catch {
            if (Test-Path -LiteralPath $backup) {
                if (Test-Path -LiteralPath $installRoot) {
                    Remove-Item -LiteralPath $installRoot -Recurse -Force
                }
                Move-Item -LiteralPath $backup -Destination $installRoot
            }
            throw
        }
        finally {
            if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
        }
    }
}
finally {
    if ($hasMutex) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}

$launcher = Join-Path $installRoot 'DesktopGoldenEye.cmd'
Start-Process -FilePath $launcher -WorkingDirectory $installRoot
