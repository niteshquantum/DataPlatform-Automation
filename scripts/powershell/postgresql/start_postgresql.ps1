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

$ProjectRoot = Get-ProjectRoot
$PgBin  = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgData = Join-Path $ProjectRoot "databases\postgresql\data"
$PgLog  = Join-Path $ProjectRoot "outputs\logs\postgresql.log"
$PgCtl = Join-Path $PgBin "pg_ctl.exe"
$Psql = Join-Path $PgBin "psql.exe"
$ServiceName = "PostgreSQLAutomation"

$LogDirectory = Split-Path $PgLog -Parent
if (!(Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

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
$PgUser = if ([string]::IsNullOrWhiteSpace($Config["POSTGRESQL_USER"])) { "postgres" } else { $Config["POSTGRESQL_USER"] }

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

$env:PGPASSWORD = $Config["POSTGRESQL_PASSWORD"]
& "$Psql" --host="$PgHost" --port="$ExpectedPort" --username="$PgUser" --dbname="$PgDatabase" --command="SELECT 1;" *> $null
$ConfiguredConnectionExitCode = $LASTEXITCODE
$env:PGPASSWORD = $null

if ($ConfiguredConnectionExitCode -eq 0) {
    Write-Log "Configured PostgreSQL is already reachable."
    Write-Log "Windows Service already running."
    exit 0
}

$ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($ExistingService) {
    if ($ExistingService.Status -eq "Running") {
        Write-Log "Windows Service already running."
        Write-Log "Reusing existing PostgreSQL instance."
        exit 0
    }

    Write-Log "Starting existing PostgreSQL service..."
    Start-Service -Name $ServiceName
}
else {
    Write-Log "Existing PostgreSQL instance detected."
    Write-Log "Reusing existing PostgreSQL instance."
}

$PgCtlOutput = Join-Path $LogDirectory "pg_ctl_start_output.log"
$PgCtlError = Join-Path $LogDirectory "pg_ctl_start_error.log"
if (Test-Path $PgCtlOutput) { Remove-Item $PgCtlOutput -Force }
if (Test-Path $PgCtlError) { Remove-Item $PgCtlError -Force }

Write-Log "Starting PostgreSQL..."
$PgCtlArguments = @("start", "-D", "`"$PgData`"", "-l", "`"$PgLog`"", "-o", "`"-p $ExpectedPort`"", "-w", "-t", "60")
$PreviousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& "$PgCtl" @PgCtlArguments > $PgCtlOutput 2> $PgCtlError
$PgCtlExitCode = $LASTEXITCODE
$ErrorActionPreference = $PreviousErrorActionPreference

if ($PgCtlExitCode -ne 0) {
    throw "pg_ctl start failed with exit code $PgCtlExitCode."
}

$PostgreSQLReady = $false
for ($Attempt = 1; $Attempt -le 30; $Attempt++) {
    Start-Sleep -Seconds 1

    & "$PgCtl" status -D "$PgData" *> $null
    $StatusExitCode = $LASTEXITCODE

    if ($StatusExitCode -eq 0) {
        try {
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $TcpClient.Connect($PgHost, $ExpectedPort)
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