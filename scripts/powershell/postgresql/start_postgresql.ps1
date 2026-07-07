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

if (!(Test-Path (Join-Path $PgData "PG_VERSION"))) {
    throw "PostgreSQL data directory is not initialized: $PgData"
}

$env:PATH = "$PgBin;$env:PATH"

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

$PgCtlProcess = Start-Process `
    -FilePath $PgCtl `
    -ArgumentList $PgCtlArguments `
    -RedirectStandardOutput $PgCtlOutput `
    -RedirectStandardError $PgCtlError `
    -WindowStyle Hidden `
    -PassThru

Write-Log "pg_ctl process started. Waiting for startup command to finish..."

$PgCtlFinished = $PgCtlProcess.WaitForExit(60000)

if (!$PgCtlFinished) {

    Write-Log "pg_ctl did not exit within 60 seconds."

    try {
        $PgCtlProcess.Kill()
    }
    catch {}

    throw "pg_ctl startup command timed out."
}

$PgCtlProcess.Refresh()

$PgCtlExitCode = $PgCtlProcess.ExitCode

# =====================================================
# DISPLAY PG_CTL OUTPUT
# =====================================================

if (Test-Path $PgCtlOutput) {

    $OutputContent = Get-Content $PgCtlOutput

    foreach ($Line in $OutputContent) {

        if (![string]::IsNullOrWhiteSpace($Line)) {
            Write-Log "pg_ctl: $Line"
        }
    }
}

if (Test-Path $PgCtlError) {

    $ErrorContent = Get-Content $PgCtlError

    foreach ($Line in $ErrorContent) {

        if (![string]::IsNullOrWhiteSpace($Line)) {
            Write-Log "pg_ctl error: $Line"
        }
    }
}

# =====================================================
# CHECK START RESULT
# =====================================================

if ($PgCtlExitCode -ne 0) {

    Write-Host ""
    Write-Host "======================================="
    Write-Host "POSTGRESQL FAILED TO START"
    Write-Host "======================================="

    if (Test-Path $PgLog) {

        Write-Host ""
        Write-Host "LAST POSTGRESQL LOG ENTRIES:"
        Write-Host ""

        Get-Content `
            $PgLog `
            -Tail 50
    }

    throw "PostgreSQL startup failed with exit code $PgCtlExitCode."
}

Write-Log "pg_ctl completed successfully."

# =====================================================
# VERIFY POSTGRESQL PROCESS
# =====================================================

Write-Log "Verifying PostgreSQL process..."

& "$PgCtl" `
    status `
    -D "$PgData" *> $null

if ($LASTEXITCODE -ne 0) {

    if (Test-Path $PgLog) {

        Write-Host ""
        Write-Host "LAST POSTGRESQL LOG ENTRIES:"
        Write-Host ""

        Get-Content `
            $PgLog `
            -Tail 50
    }

    throw "PostgreSQL process verification failed."
}

Write-Log "PostgreSQL process is running."

# =====================================================
# VERIFY PORT
# =====================================================

Write-Log "Verifying PostgreSQL port..."

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
    throw "PostgreSQL started but port $ExpectedPort is not reachable."
}

Write-Log "PostgreSQL port is reachable."

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
