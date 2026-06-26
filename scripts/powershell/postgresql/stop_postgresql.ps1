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
$StopOutput = & "$PgCtl" -D "$PgData" stop -m fast -w 2>&1
Write-Log "pg_ctl stop: $StopOutput"

# Verify actually stopped
$StatusOutput = & "$PgCtl" -D "$PgData" status 2>&1
if (($StatusOutput -join " ") -match "no server running") {
    Write-Log "PostgreSQL stopped successfully"
} else {
    Write-Log "Force killing remaining postgres processes..."
    Get-Process -Name "postgres" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    # Clean up stale pid file
    $PidFile = Join-Path $PgData "postmaster.pid"
    if (Test-Path $PidFile) { Remove-Item $PidFile -Force }
    Write-Log "PostgreSQL force stopped"
}

exit 0