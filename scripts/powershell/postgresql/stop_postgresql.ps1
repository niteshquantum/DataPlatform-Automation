$ErrorActionPreference = "SilentlyContinue"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

$PgBin  = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgData = Join-Path $ProjectRoot "databases\postgresql\data"
$PgCtl  = Join-Path $PgBin "pg_ctl.exe"

if (!(Test-Path $PgCtl)) {
    Write-Log "pg_ctl not found - skipping stop"
    exit 0
}

Write-Log "Stopping PostgreSQL..."
$StopOutput = & "$PgCtl" -D "$PgData" -m fast stop 2>&1
Write-Log "pg_ctl stop: $StopOutput"

Write-Log "PostgreSQL stopped successfully"
exit 0