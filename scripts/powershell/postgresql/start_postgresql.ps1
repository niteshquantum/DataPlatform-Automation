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
# PROJECT PATHS
# =====================================================

$ProjectRoot = Get-ProjectRoot

$PgBin  = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgData = Join-Path $ProjectRoot "databases\postgresql\data"
$PgLog  = Join-Path $ProjectRoot "outputs\logs\postgresql.log"

$PgCtl = Join-Path $PgBin "pg_ctl.exe"

# Stable Windows service name
$ServiceName = "DataPlatformPostgreSQL"

# =====================================================
# CREATE LOG DIRECTORY
# =====================================================

$LogDirectory = Split-Path $PgLog -Parent

if (!(Test-Path $LogDirectory)) {
    New-Item `
        -ItemType Directory `
        -Path $LogDirectory `
        -Force | Out-Null
}

# =====================================================
# READ CONFIGURATION
# =====================================================

$ConfigFile = Join-Path $ProjectRoot "config\windows\postgresql.conf"

if (!(Test-Path $ConfigFile)) {
    throw "Configuration file not found: $ConfigFile"
}

$Config = @{}

Get-Content $ConfigFile | ForEach-Object {

    if ($_ -match "^([^#=]+)=(.*)$") {

        $Config[
            $Matches[1].Trim()
        ] = $Matches[2].Trim()
    }
}

$PgHost = $Config["POSTGRESQL_HOST"]

$ExpectedPort = [int]$Config["POSTGRESQL_PORT"]

$PgDatabase = $Config["POSTGRESQL_DB"]

$PgUser = if (
    [string]::IsNullOrWhiteSpace(
        $Config["POSTGRESQL_USER"]
    )
) {
    "postgres"
}
else {
    $Config["POSTGRESQL_USER"]
}

# =====================================================
# VALIDATION
# =====================================================

if ([string]::IsNullOrWhiteSpace($PgHost)) {
    throw "POSTGRESQL_HOST missing."
}

if ([string]::IsNullOrWhiteSpace($PgDatabase)) {
    throw "POSTGRESQL_DB missing."
}

if ($ExpectedPort -le 0) {
    throw "Invalid POSTGRESQL_PORT."
}

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl.exe not found: $PgCtl"
}

if (!(Test-Path (Join-Path $PgData "PG_VERSION"))) {
    throw "PostgreSQL data directory is not initialized: $PgData"
}

Write-Log ""
Write-Log "======================================="
Write-Log "POSTGRESQL SERVICE START"
Write-Log "======================================="

Write-Log "Project Root : $ProjectRoot"
Write-Log "Host         : $PgHost"
Write-Log "Port         : $ExpectedPort"
Write-Log "Database     : $PgDatabase"
Write-Log "User         : $PgUser"
Write-Log "Service      : $ServiceName"
Write-Log "Data Dir     : $PgData"

# =====================================================
# CHECK WINDOWS SERVICE
# =====================================================

$Service = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

# =====================================================
# IF SERVICE EXISTS
# =====================================================

if ($Service) {

    Write-Log "PostgreSQL Windows Service already exists."

    # -------------------------------------------------
    # STOP SERVICE IF RUNNING
    # -------------------------------------------------

    if ($Service.Status -eq "Running") {

        Write-Log "Stopping existing PostgreSQL service..."

        Stop-Service `
            -Name $ServiceName `
            -Force

        $Service.WaitForStatus(
            "Stopped",
            (New-TimeSpan -Seconds 60)
        )

        Write-Log "Existing service stopped."
    }

    # -------------------------------------------------
    # REMOVE OLD SERVICE REGISTRATION
    # -------------------------------------------------

    Write-Log "Removing old PostgreSQL service registration..."

    & "$PgCtl" `
        unregister `
        -N "$ServiceName"

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to unregister old PostgreSQL service."
    }

    Start-Sleep -Seconds 2

    Write-Log "Old service registration removed."
}

# =====================================================
# CHECK PORT
# =====================================================

$PortConnection = Get-NetTCPConnection `
    -LocalPort $ExpectedPort `
    -State Listen `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($PortConnection) {

    $OwnerProcessId = $PortConnection.OwningProcess

    $OwnerProcess = Get-Process `
        -Id $OwnerProcessId `
        -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "======================================="
    Write-Host "PORT CONFLICT"
    Write-Host "======================================="

    Write-Host "Port       : $ExpectedPort"
    Write-Host "Process ID : $OwnerProcessId"

    if ($OwnerProcess) {
        Write-Host "Process    : $($OwnerProcess.ProcessName)"
    }

    throw "Port $ExpectedPort is already occupied."
}

# =====================================================
# REGISTER WINDOWS SERVICE
# =====================================================

Write-Log "Registering PostgreSQL Windows Service..."

& "$PgCtl" `
    register `
    -N "$ServiceName" `
    -D "$PgData" `
    -o "-p $ExpectedPort"

if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL Windows Service registration failed."
}

Write-Log "PostgreSQL Windows Service registered successfully."

# =====================================================
# START WINDOWS SERVICE
# =====================================================

Write-Log "Starting PostgreSQL Windows Service..."

Start-Service `
    -Name $ServiceName

$Service = Get-Service `
    -Name $ServiceName

$Service.WaitForStatus(
    "Running",
    (New-TimeSpan -Seconds 60)
)

Write-Log "PostgreSQL Windows Service is running."

# =====================================================
# VERIFY PORT
# =====================================================

Write-Log "Checking PostgreSQL port..."

$PortReady = $false

for ($Attempt = 1; $Attempt -le 15; $Attempt++) {

    try {

        $TcpClient = New-Object System.Net.Sockets.TcpClient

        $TcpClient.Connect(
            $PgHost,
            $ExpectedPort
        )

        $TcpClient.Close()

        $PortReady = $true

        break
    }
    catch {

        Write-Log "Waiting for PostgreSQL port... $Attempt/15"

        Start-Sleep -Seconds 1
    }
}

if (!$PortReady) {
    throw "PostgreSQL service started but port $ExpectedPort is not reachable."
}

# =====================================================
# FINAL SERVICE VALIDATION
# =====================================================

$Service = Get-Service `
    -Name $ServiceName `
    -ErrorAction Stop

if ($Service.Status -ne "Running") {
    throw "PostgreSQL Windows Service is not running."
}

# =====================================================
# SUCCESS
# =====================================================

Write-Log ""
Write-Log "======================================="
Write-Log "POSTGRESQL START COMPLETED"
Write-Log "======================================="

Write-Log "Service   : $ServiceName"
Write-Log "Status    : $($Service.Status)"
Write-Log "Host      : $PgHost"
Write-Log "Port      : $ExpectedPort"
Write-Log "Database  : $PgDatabase"
Write-Log "User      : $PgUser"
Write-Log "Data Dir  : $PgData"

exit 0
