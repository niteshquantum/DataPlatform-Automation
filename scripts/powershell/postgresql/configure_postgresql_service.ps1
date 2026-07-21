$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING POSTGRESQL WINDOWS SERVICE"
Write-Host "====================================="
Write-Host ""

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$PgBin  = "$PROJECT_ROOT\databases\postgresql\bin"
$PgData = "$PROJECT_ROOT\databases\postgresql\data"
$PgLogDir = "$PROJECT_ROOT\outputs\logs"
$PgLog  = "$PgLogDir\postgresql_service.log"
$PgCtl = "$PgBin\pg_ctl.exe"
$ServiceName = "PostgreSQLAutomation"

$ConfigFile = "$PROJECT_ROOT\config\windows\postgresql.conf"

if (!(Test-Path $ConfigFile)) {
    throw "Config file not found: $ConfigFile"
}

$Config = @{}
Get-Content $ConfigFile | ForEach-Object {
    $Line = $_.Trim()

    if ($Line -and -not $Line.StartsWith("#") -and $Line.Contains("=")) {
        $Key, $Value = $Line.Split("=", 2)
        $Config[$Key.Trim()] = $Value.Trim()
    }
}

$PgHost     = $Config["POSTGRESQL_HOST"]
$PgPort     = $Config["POSTGRESQL_PORT"]
$PgDatabase = $Config["POSTGRESQL_DB"]
$PgUser     = $Config["POSTGRESQL_USER"]

if (-not $PgHost) {
    throw "POSTGRESQL_HOST not found in postgresql.conf"
}

if (-not $PgPort) {
    throw "POSTGRESQL_PORT not found in postgresql.conf"
}

if (-not $PgUser) {
    throw "POSTGRESQL_USER not found in postgresql.conf"
}

Write-Host "Project Root : $PROJECT_ROOT"
Write-Host "PostgreSQL   : $PgCtl"
Write-Host "Data Path    : $PgData"
Write-Host "Log Path     : $PgLog"
Write-Host "Host         : $PgHost"
Write-Host "Port         : $PgPort"
Write-Host "Database     : $PgDatabase"
Write-Host "User         : $PgUser"
Write-Host "Service      : $ServiceName"
Write-Host ""

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl.exe not found: $PgCtl"
}

if (!(Test-Path "$PgData\PG_VERSION")) {
    throw "PostgreSQL data directory is not initialized: $PgData"
}

if (!(Test-Path $PgLogDir)) {
    New-Item -ItemType Directory -Path $PgLogDir -Force | Out-Null
}

$ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($ExistingService) {
    Write-Host "Existing PostgreSQL service detected."

    if ($ExistingService.Status -eq "Running") {
        Write-Host "Windows Service already running."
    }
    else {
        Write-Host "Starting existing PostgreSQL service..."
        Start-Service -Name $ServiceName
    }
}
else {
    $PortListener = Get-NetTCPConnection -LocalPort $PgPort -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($PortListener) {
        Write-Host "Existing PostgreSQL instance detected on port $PgPort."
        Write-Host "Reusing existing PostgreSQL instance."
    }
    else {
        Write-Host "Registering PostgreSQL Windows Service..."
        & $PgCtl register -N $ServiceName -D $PgData -S auto -o "-p $PgPort"

        if ($LASTEXITCODE -ne 0) {
            throw "PostgreSQL service registration failed"
        }
    }

    Write-Host "Starting PostgreSQL Windows Service..."
    Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
}

$ServiceStarted = $false
for ($i = 1; $i -le 60; $i++) {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($Service -and $Service.Status -eq "Running") {
        $ServiceStarted = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $ServiceStarted) {
    throw "PostgreSQL Windows Service failed to start"
}

$PortStarted = $false
for ($i = 1; $i -le 60; $i++) {
    $PortConnection = Get-NetTCPConnection -LocalPort $PgPort -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($PortConnection) {
        $PortStarted = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $PortStarted) {
    throw "PostgreSQL is not listening on port $PgPort"
}

Write-Host ""
Write-Host "====================================="
Write-Host "POSTGRESQL WINDOWS SERVICE CONFIGURED"
Write-Host "====================================="
Write-Host ""
Write-Host "Service : $ServiceName"
Write-Host "Status  : Running"
Write-Host "Startup : Automatic"
Write-Host "Host    : $PgHost"
Write-Host "Port    : $PgPort"
Write-Host ""

exit 0
