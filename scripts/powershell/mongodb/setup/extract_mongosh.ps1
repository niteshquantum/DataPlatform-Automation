$ErrorActionPreference = "Stop"

$ZipPath = [System.IO.Path]::GetFullPath($env:ZIP_PATH)
$DestinationRoot = [System.IO.Path]::GetFullPath($env:DESTINATION_ROOT)
$TargetFolderName = $env:TARGET_FOLDER

if ([string]::IsNullOrWhiteSpace($ZipPath)) {
    throw "ZIP_PATH environment variable is required."
}

if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
    throw "DESTINATION_ROOT environment variable is required."
}

if ([string]::IsNullOrWhiteSpace($TargetFolderName)) {
    throw "TARGET_FOLDER environment variable is required."
}

if (!(Test-Path $ZipPath)) {
    throw "Archive not found: $ZipPath"
}

$TargetDir = Join-Path $DestinationRoot $TargetFolderName
$TempDir = Join-Path $DestinationRoot ("_extract_" + [Guid]::NewGuid().ToString())

if (!(Test-Path $DestinationRoot)) {
    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
}

if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}

try {
    Write-Host "Validating archive: $ZipPath"
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force
    Write-Host "Archive validated successfully."

    $extractedFolder = Get-ChildItem $TempDir -Directory |
        Where-Object { $_.Name -like "mongosh-*" } |
        Select-Object -First 1

    if ($null -eq $extractedFolder) {
        throw "No mongosh-* folder found in archive"
    }

    $MongoshExe = Join-Path $extractedFolder.FullName "bin\mongosh.exe"
    if (!(Test-Path -LiteralPath $MongoshExe -PathType Leaf)) {
        throw "Archive does not contain bin\\mongosh.exe in the mongosh distribution folder."
    }

    # Do not replace a working installation until the new archive has been
    # fully extracted and its required executable has been verified.
    if (Test-Path $TargetDir) {
        Write-Host "Removing existing folder: $TargetDir"
        Remove-Item $TargetDir -Recurse -Force
    }

    Move-Item $extractedFolder.FullName $TargetDir -Force

    Write-Host ""
    Write-Host "==================================="
    Write-Host "EXTRACTION COMPLETE"
    Write-Host "==================================="
    Write-Host "Archive   : $ZipPath"
    Write-Host "Target    : $TargetDir"
    Write-Host "==================================="
    Write-Host ""
}
catch {
    throw
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
