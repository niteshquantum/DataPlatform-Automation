$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

$DriverDir = Join-Path $ProjectRoot "tools\drivers"

if (!(Test-Path $DriverDir)) {
    New-Item -ItemType Directory -Path $DriverDir -Force | Out-Null
}

$JarFile = Join-Path $DriverDir "mssql-jdbc.jar"

if (Test-Path $JarFile) {
    Write-Host "SQL Server JDBC Driver already exists."
    exit 0
}

$DownloadUrl = "https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.8.1.jre11/mssql-jdbc-12.8.1.jre11.jar"

Write-Host "Downloading SQL Server JDBC Driver..."

Invoke-WebRequest `
    -Uri $DownloadUrl `
    -OutFile $JarFile `
    -UseBasicParsing

if (!(Test-Path $JarFile)) {
    Write-Error "SQL Server JDBC Driver download failed."
    exit 1
}

Write-Host "SQL Server JDBC Driver downloaded successfully."