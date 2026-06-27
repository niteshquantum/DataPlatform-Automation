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
$PgLog  = Join-Path $ProjectRoot "outputs\logs\postgresql.log"
$PgCtl  = Join-Path $PgBin "pg_ctl.exe"

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl not found: $PgCtl"
}

$env:PATH = "$PgBin;$env:PATH"

Write-Log "pg_ctl : $PgCtl"
Write-Log "Data   : $PgData"
Write-Log "Log    : $PgLog"

# Already running
& "$PgCtl" -D "$PgData" status *> $null

if ($LASTEXITCODE -eq 0) {
    Write-Log "PostgreSQL already running."
    exit 0
}

Write-Log "Starting PostgreSQL..."

& "$PgCtl" `
    -D "$PgData" `
    -l "$PgLog" `
    start

if ($LASTEXITCODE -ne 0) {
    throw "Unable to start PostgreSQL"
}

Start-Sleep -Seconds 5

& "$PgCtl" -D "$PgData" status

if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL failed to start"
}

Write-Log "PostgreSQL started successfully."

exit 0