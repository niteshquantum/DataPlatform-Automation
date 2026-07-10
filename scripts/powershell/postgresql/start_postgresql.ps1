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
$Psql = Join-Path $PgBin "psql.exe"

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
        $Config[$Matches[1].Trim()] = $Matches[2].Trim()
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

if (!(Test-Path $Psql)) {
    throw "psql.exe not found: $Psql"
}

if (!(Test-Path (Join-Path $PgData "PG_VERSION"))) {
    throw "PostgreSQL data directory is not initialized: $PgData"
}

# =====================================================
# START REPORT
# =====================================================

Write-Log ""
Write-Log "======================================="
Write-Log "POSTGRESQL START"
Write-Log "======================================="

Write-Log "Project Root : $ProjectRoot"
Write-Log "Host         : $PgHost"
Write-Log "Port         : $ExpectedPort"
Write-Log "Database     : $PgDatabase"
Write-Log "User         : $PgUser"
Write-Log "pg_ctl       : $PgCtl"
Write-Log "Data Dir     : $PgData"
Write-Log "Log File     : $PgLog"

# =====================================================
# CHECK CONFIGURED CONNECTION
# =====================================================

Write-Log "Checking configured PostgreSQL connection..."

$env:PGPASSWORD = $Config["POSTGRESQL_PASSWORD"]

& "$Psql" `
    --host="$PgHost" `
    --port="$ExpectedPort" `
    --username="$PgUser" `
    --dbname="$PgDatabase" `
    --command="SELECT 1;" *> $null

$ConfiguredConnectionExitCode = $LASTEXITCODE

$env:PGPASSWORD = $null

if ($ConfiguredConnectionExitCode -eq 0) {

    Write-Log "Configured PostgreSQL is already reachable."

    Write-Log ""
    Write-Log "======================================="
    Write-Log "POSTGRESQL START COMPLETED"
    Write-Log "======================================="

    Write-Log "Host      : $PgHost"
    Write-Log "Port      : $ExpectedPort"
    Write-Log "Database  : $PgDatabase"
    Write-Log "User      : $PgUser"
    Write-Log "Data Dir  : $PgData"

    exit 0
}

# =====================================================
# CHECK CURRENT PROJECT INSTANCE
# =====================================================

Write-Log "Checking current PostgreSQL instance..."

& "$PgCtl" `
    status `
    -D "$PgData" *> $null

if ($LASTEXITCODE -eq 0) {

    Write-Log "Current project PostgreSQL is already running."

    Write-Log ""
    Write-Log "======================================="
    Write-Log "POSTGRESQL START COMPLETED"
    Write-Log "======================================="

    Write-Log "Host      : $PgHost"
    Write-Log "Port      : $ExpectedPort"
    Write-Log "Database  : $PgDatabase"
    Write-Log "User      : $PgUser"
    Write-Log "Data Dir  : $PgData"

    exit 0
}

Write-Log "Current project PostgreSQL is not running."

# =====================================================
# CHECK PORT
# =====================================================

Write-Log "Checking configured port $ExpectedPort..."

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

    if ($OwnerProcess -and $OwnerProcess.ProcessName -eq "postgres") {

        Write-Host ""
        Write-Host "Detected PostgreSQL on configured port. Validating connection..."

        $env:PGPASSWORD = $Config["POSTGRESQL_PASSWORD"]

        & "$Psql" `
            --host="$PgHost" `
            --port="$ExpectedPort" `
            --username="$PgUser" `
            --dbname="postgres" `
            --command="SELECT 1;" *> $null

        $PsqlExitCode = $LASTEXITCODE

        $env:PGPASSWORD = $null

        if ($PsqlExitCode -eq 0) {

            Write-Host ""
            Write-Host "======================================="
            Write-Host "POSTGRESQL START COMPLETED"
            Write-Host "======================================="
            Write-Host "Configured PostgreSQL is already reachable."
            Write-Host "Host      : $PgHost"
            Write-Host "Port      : $ExpectedPort"
            Write-Host "User      : $PgUser"
            Write-Host ""

            exit 0
        }
    }

    throw "Port $ExpectedPort is already occupied."
}

Write-Log "Port $ExpectedPort is available."

# =====================================================
# PREPARE PG_CTL OUTPUT FILES
# =====================================================

$PgCtlOutput = Join-Path $LogDirectory "pg_ctl_start_output.log"

$PgCtlError = Join-Path $LogDirectory "pg_ctl_start_error.log"

if (Test-Path $PgCtlOutput) {
    Remove-Item $PgCtlOutput -Force
}

if (Test-Path $PgCtlError) {
    Remove-Item $PgCtlError -Force
}
# =====================================================
# START POSTGRESQL
# =====================================================

Write-Log "Starting PostgreSQL..."

$PgCtlArguments = @(
    "start"
    "-D"
    "`"$PgData`""
    "-l"
    "`"$PgLog`""
    "-o"
    "`"-p $ExpectedPort`""
    "-w"
    "-t"
    "60"
)

$PreviousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& "$PgCtl" @PgCtlArguments > $PgCtlOutput 2> $PgCtlError
$PgCtlExitCode = $LASTEXITCODE
$ErrorActionPreference = $PreviousErrorActionPreference

if ($PgCtlExitCode -ne 0) {
    throw "pg_ctl start failed with exit code $PgCtlExitCode."
}

Write-Log "pg_ctl start completed."

# =====================================================
# WAIT FOR POSTGRESQL READINESS
# =====================================================

$PostgreSQLReady = $false

for ($Attempt = 1; $Attempt -le 30; $Attempt++) {

    Start-Sleep -Seconds 1

    & "$PgCtl" `
        status `
        -D "$PgData" *> $null

    $StatusExitCode = $LASTEXITCODE

    if ($StatusExitCode -eq 0) {

        try {

            $TcpClient = New-Object System.Net.Sockets.TcpClient

            $TcpClient.Connect(
                $PgHost,
                $ExpectedPort
            )

            $TcpClient.Close()

            $PostgreSQLReady = $true

            Write-Log "PostgreSQL process is running."
            Write-Log "PostgreSQL port is reachable."

            break
        }
        catch {
            Write-Log "PostgreSQL process started. Waiting for port... $Attempt/30"
        }
    }
    else {
        Write-Log "Waiting for PostgreSQL startup... $Attempt/30"
    }
}

# =====================================================
# CHECK START RESULT
# =====================================================

if (!$PostgreSQLReady) {

    Write-Host ""
    Write-Host "======================================="
    Write-Host "POSTGRESQL FAILED TO START"
    Write-Host "======================================="

    if (Test-Path $PgCtlOutput) {

        Write-Host ""
        Write-Host "PG_CTL OUTPUT:"
        Write-Host ""

        Get-Content $PgCtlOutput
    }

    if (Test-Path $PgCtlError) {

        Write-Host ""
        Write-Host "PG_CTL ERROR:"
        Write-Host ""

        Get-Content $PgCtlError
    }

    if (Test-Path $PgLog) {

        Write-Host ""
        Write-Host "LAST POSTGRESQL LOG ENTRIES:"
        Write-Host ""

        Get-Content $PgLog -Tail 50
    }

    throw "PostgreSQL failed to become ready within 30 seconds."
}

Write-Log "PostgreSQL startup completed successfully."

# =====================================================
# SUCCESS
# =====================================================

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
