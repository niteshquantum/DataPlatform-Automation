$ErrorActionPreference = "Stop"

# Project root
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

# tools\liquibase path
$LiquibaseDir = Join-Path $ProjectRoot "tools\liquibase"

if (Test-Path "$LiquibaseDir\liquibase.bat") {
    Write-Host "Liquibase already exists."
    exit 0
}

if (!(Test-Path $LiquibaseDir)) {
    New-Item -ItemType Directory -Path $LiquibaseDir -Force | Out-Null
}

$ZipFile = Join-Path $LiquibaseDir "liquibase.zip"

Write-Host "Downloading Liquibase..."

Invoke-WebRequest `
-Uri "https://github.com/liquibase/liquibase/releases/download/v5.0.1/liquibase-5.0.1.zip" `
-OutFile $ZipFile

Expand-Archive $ZipFile $LiquibaseDir -Force

Remove-Item $ZipFile -Force

Write-Host "Liquibase downloaded successfully."