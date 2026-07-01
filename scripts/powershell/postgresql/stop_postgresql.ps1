$ErrorActionPreference = "Stop"

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
    throw "pg_ctl.exe not found: $PgCtl"
}

$env:PATH = "$PgBin;$env:PATH"

Write-Log "Checking PostgreSQL status..."

& "$PgCtl" -D "$PgData" status *> $null

if ($LASTEXITCODE -ne 0) {
    Write-Log "Project PostgreSQL is already stopped."
    exit 0
}

Write-Log "Stopping Project PostgreSQL..."

& "$PgCtl" `
    -D "$PgData" `
    stop `
    -m fast

if ($LASTEXITCODE -ne 0) {
    throw "Failed to stop Project PostgreSQL."
}

Start-Sleep -Seconds 2

& "$PgCtl" -D "$PgData" status *> $null

if ($LASTEXITCODE -eq 0) {
    throw "Project PostgreSQL is still running."
}

Write-Log "Project PostgreSQL stopped successfully."

exit 0