
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
$LogDirectory = Split-Path $PgLog -Parent

if (!(Test-Path $LogDirectory)) {

    New-Item `
        -ItemType Directory `
        -Path $LogDirectory `
        -Force | Out-Null

}
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

$PgHost = $Config["POSTGRESQL_HOST"]

$ExpectedPort = [int]$Config["POSTGRESQL_PORT"]

$PgDatabase = $Config["POSTGRESQL_DB"]

$PgUser = if ([string]::IsNullOrWhiteSpace($Config["POSTGRESQL_USER"])) {
    "postgres"
}
else {
    $Config["POSTGRESQL_USER"]
}

$PgPassword = $Config["POSTGRESQL_PASSWORD"]
if ([string]::IsNullOrWhiteSpace($PgHost)) {
    throw "POSTGRESQL_HOST missing."
}

if ([string]::IsNullOrWhiteSpace($PgDatabase)) {
    throw "POSTGRESQL_DB missing."
}

if ($ExpectedPort -le 0) {
    throw "Invalid POSTGRESQL_PORT."
}

Write-Log "Host      : $PgHost"
Write-Log "Port      : $ExpectedPort"
Write-Log "Database  : $PgDatabase"
Write-Log "User      : $PgUser"

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

    $Process = Get-Process -Id $PortInUse[0].OwningProcess -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "==============================================="
    Write-Host " PORT CONFLICT DETECTED"
    Write-Host "==============================================="
    Write-Host ""

    Write-Host "Configured Port : $ExpectedPort"
    Write-Host "Process ID      : $($PortInUse[0].OwningProcess)"

    if ($Process) {
        Write-Host "Process Name    : $($Process.ProcessName)"
    }

    Write-Host ""
    Write-Host "Another application is using this port."
    Write-Host "Stop that application or change POSTGRESQL_PORT."

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

Write-Log "Starting PostgreSQL..."
Write-Log "Using configuration from : $ConfigFile"

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

Write-Log ""

Write-Log "======================================="
Write-Log "POSTGRESQL START COMPLETED"
Write-Log "======================================="
Write-Log "Host      : $PgHost"
Write-Log "Port      : $ExpectedPort"
Write-Log "Database  : $PgDatabase"
Write-Log "User      : $PgUser"
Write-Log "Data Dir  : $PgData"
Write-Log "Log File  : $PgLog"

exit 0

