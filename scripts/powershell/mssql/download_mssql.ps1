$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "DOWNLOADING MSSQL SERVER"
Write-Host "====================================="
Write-Host ""

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$DownloadDir = "$PROJECT_ROOT\databases\mssql\downloads"

if (!(Test-Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
}

$Installer = "$DownloadDir\SQLServer2022-DEV-x64-ENU.exe"

if (Test-Path $Installer) {

    Write-Host "SQL Server installer already exists."
    Write-Host $Installer
    exit 0

}

$Url = "https://download.microsoft.com/download/3/8/d/38de7036-2433-4207-8eae-06e247e17b25/SQLServer2022-DEV-x64-ENU.exe"

Write-Host "Downloading SQL Server Developer Edition..."
Write-Host ""

Invoke-WebRequest `
    -Uri $Url `
    -OutFile $Installer `
    -UseBasicParsing

if (!(Test-Path $Installer)) {
    throw "SQL Server download failed."
}

Write-Host ""
Write-Host "====================================="
Write-Host "DOWNLOAD COMPLETED"
Write-Host "Installer : $Installer"
Write-Host "====================================="
Write-Host ""

exit 0