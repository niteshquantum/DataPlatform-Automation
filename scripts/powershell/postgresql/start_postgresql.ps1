
$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

function Get-ProjectRoot {
    $Root = Split-Path $PSScriptRoot -Parent
    $Root = Split-Path $Root -Parent
    $Root = Split-Path $Root -Parent
    return $Root
}

# =====================================================
# Project Paths
# =====================================================

$ProjectRoot = Get-ProjectRoot

$PgBin  = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgData = Join-Path $ProjectRoot "databases\postgresql\data"
$PgLog  = Join-Path $ProjectRoot "outputs\logs\postgresql.log"
$PgCtl  = Join-Path $PgBin "pg_ctl.exe"

# =====================================================
# Read Configuration
# =====================================================

$ConfigFile = Join-Path $ProjectRoot "config\windows\postgresql.conf"

if (!(Test-Path $ConfigFile)) {
    throw "Configuration file not found: $ConfigFile"
}

$Config = @{}

Get-Content $ConfigFile | ForEach-Object {

    if ($_ -match "^([^#=]+)=(.*)$") {
        $Config[$Matches[1].Trim()] = $Matches[2].Trim()
    }

}

$ExpectedPort = [int]$Config["POSTGRESQL_PORT"]

# ------------------------------------------------------------
# Check if configured port is already in use
# ------------------------------------------------------------

# ------------------------------------------------------------
# Check if PostgreSQL is already running
# ------------------------------------------------------------

& "$PgCtl" -D "$PgData" status *> $null

if ($LASTEXITCODE -eq 0) {

    Write-Log "Project PostgreSQL is already running."
    exit 0
}

# ------------------------------------------------------------
# Check whether configured port is occupied
# ------------------------------------------------------------

$PortInUse = Get-NetTCPConnection `
    -LocalPort $ExpectedPort `
    -State Listen `
    -ErrorAction SilentlyContinue

if ($PortInUse) {

    Write-Host ""
    Write-Host "==============================================="
    Write-Host " PORT CONFLICT DETECTED"
    Write-Host "==============================================="
    Write-Host ""

    Write-Host "Configured Port : $ExpectedPort"
    Write-Host "Process ID      : $($PortInUse.OwningProcess)"
    Write-Host ""
    Write-Host "Another process is using this port."
    Write-Host "Stop that process or change POSTGRESQL_PORT."

    throw "Port conflict detected."
}

# =====================================================
# Validation
# =====================================================

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl not found: $PgCtl"
}

$env:PATH = "$PgBin;$env:PATH"

Write-Log "pg_ctl        : $PgCtl"
Write-Log "Data Directory: $PgData"
Write-Log "Log File      : $PgLog"
Write-Log "Port          : $ExpectedPort"

# =====================================================
# Already Running?
# =====================================================

& "$PgCtl" -D "$PgData" status *> $null

if ($LASTEXITCODE -eq 0) {
    Write-Log "PostgreSQL is already running."
    exit 0
}

# =====================================================
# Start PostgreSQL
# =====================================================

$LogDir = Split-Path $PgLog -Parent

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

Write-Log "Starting PostgreSQL..."

& "$PgCtl" `
    start `
    -D "$PgData" `
    -l "$PgLog" `
    -o "-p $ExpectedPort" `
    -w

if ($LASTEXITCODE -ne 0) {

    Write-Host ""
    Write-Host "==============================================="
    Write-Host "POSTGRESQL FAILED TO START"
    Write-Host "==============================================="
    Write-Host ""

    if (Test-Path $PgLog) {
        Write-Host "PostgreSQL Log:"
        Get-Content $PgLog -Tail 50
    }

    throw "Unable to start PostgreSQL."
}

Start-Sleep -Seconds 3

# =====================================================
# Verify
# =====================================================

& "$PgCtl" status -D "$PgData"

if ($LASTEXITCODE -ne 0) {

    if (Test-Path $PgLog) {
        Write-Host ""
        Write-Host "Last PostgreSQL Log Entries:"
        Get-Content $PgLog -Tail 50
    }

    throw "PostgreSQL failed to start."
}

Write-Log "PostgreSQL started successfully."

Write-Log "Host : 127.0.0.1"
Write-Log "Port : $ExpectedPort"
Write-Log "Data : $PgData"

exit 0

