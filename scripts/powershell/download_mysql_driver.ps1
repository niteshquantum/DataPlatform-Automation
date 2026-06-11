$ErrorActionPreference = "Stop"

# Project root directory
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

# tools\drivers path
$DriverDir = Join-Path $ProjectRoot "tools\drivers"

if (!(Test-Path $DriverDir)) {
    New-Item -ItemType Directory -Path $DriverDir -Force | Out-Null
}

$JarFile = Join-Path $DriverDir "mysql-connector-j-9.5.0.jar"

if (Test-Path $JarFile) {
    Write-Host "MySQL Connector already exists."
    exit 0
}

Write-Host "Downloading MySQL Connector..."

Invoke-WebRequest `
-Uri "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/9.5.0/mysql-connector-j-9.5.0.jar" `
-OutFile $JarFile

Write-Host "MySQL Driver downloaded successfully."