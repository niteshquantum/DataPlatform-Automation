$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

# scripts\powershell\ se 2 level up = project root
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$DriversDir  = Join-Path $ProjectRoot "tools\drivers"
$JarPath     = Join-Path $DriversDir "postgresql-42.7.3.jar"
$DownloadUrl = "https://jdbc.postgresql.org/download/postgresql-42.7.3.jar"

Write-Log "Drivers Dir : $DriversDir"

if (!(Test-Path $DriversDir)) {
    New-Item -ItemType Directory -Path $DriversDir -Force | Out-Null
    Write-Log "Created drivers directory"
}

if (Test-Path $JarPath) {
    Write-Log "PostgreSQL JDBC Driver already exists - skipping download"
    exit 0
}

Write-Log "Downloading PostgreSQL JDBC Driver..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $DownloadUrl -OutFile $JarPath -UseBasicParsing -TimeoutSec 120
Write-Log "Driver downloaded: $JarPath"
exit 0