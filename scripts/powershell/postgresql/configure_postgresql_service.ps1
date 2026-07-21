$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

function Resolve-ExistingPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    if (Test-Path -LiteralPath $Path -PathType Container) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return $null
}

function Wait-ForServiceState {
    param(
        [string]$Name,
        [string[]]$ExpectedStates,
        [int]$TimeoutSeconds = 60
    )

    $Deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $Deadline) {
        $Service = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($Service -and $ExpectedStates -contains $Service.Status) {
            return $Service
        }

        Start-Sleep -Seconds 1
    }

    return Get-Service -Name $Name -ErrorAction SilentlyContinue
}

function Get-ServiceImagePath {
    param([string]$Name)

    $ServiceInfo = Get-CimInstance Win32_Service -Filter "Name='$Name'" -ErrorAction SilentlyContinue
    if ($ServiceInfo -and $ServiceInfo.PathName) {
        return $ServiceInfo.PathName.Trim('"')
    }

    return $null
}

function Test-ServiceImageMatchesDeployment {
    param(
        [string]$ServiceImagePath,
        [string]$CurrentPgCtl,
        [string]$CurrentDataDir
    )

    if ([string]::IsNullOrWhiteSpace($ServiceImagePath)) {
        return $false
    }

    return ($ServiceImagePath -match [regex]::Escape($CurrentPgCtl)) -and ($ServiceImagePath -match [regex]::Escape($CurrentDataDir))
}

function Register-PostgreSQLService {
    param(
        [string]$PgCtl,
        [string]$PgData,
        [string]$PgPort,
        [string]$ServiceName
    )

    Write-Log "Registering PostgreSQL Windows service for the current deployment..."

    $ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($ExistingService) {
        Write-Log "Stopping existing service before re-registration..."
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    try {
        & $PgCtl unregister -N $ServiceName *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "pg_ctl unregister returned exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Log "pg_ctl unregister unavailable or failed. Falling back to service delete."
        & sc.exe delete $ServiceName *> $null
    }

    & $PgCtl register -N $ServiceName -D $PgData -S auto -o "-p $PgPort" *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL service registration failed with exit code $LASTEXITCODE"
    }

    $RegisteredService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $RegisteredService) {
        throw "Service registration did not produce a Windows service entry."
    }

    Write-Log "Service registered successfully."
}

function Write-ServiceFailureDetails {
    param(
        [string]$ServiceName,
        [string]$PgCtl,
        [string]$PgData,
        [string]$PgLog,
        [int]$PgPort,
        [string]$Reason
    )

    Write-Host ""
    Write-Host "====================================="
    Write-Host "POSTGRESQL SERVICE START FAILED"
    Write-Host "====================================="
    Write-Host "Service     : $ServiceName"
    Write-Host "Reason      : $Reason"
    Write-Host "Port        : $PgPort"
    Write-Host "Data Dir    : $PgData"
    Write-Host "Log File    : $PgLog"
    Write-Host ""

    $ServiceInfo = Get-CimInstance Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
    if ($ServiceInfo) {
        Write-Host "Service State      : $($ServiceInfo.State)"
        Write-Host "Service StartMode  : $($ServiceInfo.StartMode)"
        Write-Host "Service Path       : $($ServiceInfo.PathName)"
        Write-Host "Service ExitCode   : $($ServiceInfo.ExitCode)"
        Write-Host ""
    }

    $DiagnosticLog = Join-Path $PgData "pg_ctl_start_output.log"
    $DiagnosticError = Join-Path $PgData "pg_ctl_start_error.log"

    if (Test-Path -LiteralPath $DiagnosticLog) {
        Write-Host "PG_CTL OUTPUT:"
        Get-Content -LiteralPath $DiagnosticLog
        Write-Host ""
    }

    if (Test-Path -LiteralPath $DiagnosticError) {
        Write-Host "PG_CTL ERROR:"
        Get-Content -LiteralPath $DiagnosticError
        Write-Host ""
    }

    if (Test-Path -LiteralPath $PgLog) {
        Write-Host "POSTGRES STARTUP LOG:"
        Get-Content -LiteralPath $PgLog -Tail 100
        Write-Host ""
    }

    try {
        $Events = Get-WinEvent -LogName System -MaxEvents 50 -ErrorAction SilentlyContinue |
            Where-Object { $_.Message -match $ServiceName -or $_.Message -match 'service' } |
            Select-Object -First 10

        if ($Events) {
            Write-Host "WINDOWS SERVICE EVENTS:"
            $Events | ForEach-Object { Write-Host $_.Message }
            Write-Host ""
        }
    }
    catch {
        Write-Host "Windows event log query was not available."
    }
}

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING POSTGRESQL WINDOWS SERVICE"
Write-Host "====================================="
Write-Host ""

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$PgBin = Join-Path $PROJECT_ROOT "databases\postgresql\bin"
$PgData = Join-Path $PROJECT_ROOT "databases\postgresql\data"
$PgLogDir = Join-Path $PROJECT_ROOT "outputs\logs"
$PgLog = Join-Path $PgLogDir "postgresql_service.log"
$PgCtl = Join-Path $PgBin "pg_ctl.exe"
$PostgresExecutable = Join-Path $PgBin "postgres.exe"
$ServiceName = "PostgreSQLAutomation"
$ConfigFile = Join-Path $PROJECT_ROOT "config\windows\postgresql.conf"

if (!(Test-Path -LiteralPath $ConfigFile)) {
    throw "Config file not found: $ConfigFile"
}

if (!(Test-Path -LiteralPath $PgLogDir)) {
    New-Item -ItemType Directory -Path $PgLogDir -Force | Out-Null
}

$Config = @{}
Get-Content -LiteralPath $ConfigFile | ForEach-Object {
    $Line = $_.Trim()

    if ($Line -and -not $Line.StartsWith("#") -and $Line.Contains("=")) {
        $Key, $Value = $Line.Split("=", 2)
        $Config[$Key.Trim()] = $Value.Trim()
    }
}

$PgHost = $Config["POSTGRESQL_HOST"]
$PgPort = $Config["POSTGRESQL_PORT"]
$PgDatabase = $Config["POSTGRESQL_DB"]
$PgUser = $Config["POSTGRESQL_USER"]

if ([string]::IsNullOrWhiteSpace($PgHost)) {
    throw "POSTGRESQL_HOST not found in postgresql.conf"
}

if ([string]::IsNullOrWhiteSpace($PgPort)) {
    throw "POSTGRESQL_PORT not found in postgresql.conf"
}

if ([string]::IsNullOrWhiteSpace($PgUser)) {
    throw "POSTGRESQL_USER not found in postgresql.conf"
}

$PgPort = [int]$PgPort

Write-Log "Project Root : $PROJECT_ROOT"
Write-Log "PostgreSQL   : $PgCtl"
Write-Log "Data Path    : $PgData"
Write-Log "Log Path     : $PgLog"
Write-Log "Host         : $PgHost"
Write-Log "Port         : $PgPort"
Write-Log "Database     : $PgDatabase"
Write-Log "User         : $PgUser"
Write-Log "Service      : $ServiceName"
Write-Log ""

$ValidationErrors = New-Object System.Collections.Generic.List[string]

if (-not (Resolve-ExistingPath -Path $PgCtl)) {
    $ValidationErrors.Add("pg_ctl.exe not found: $PgCtl")
}

if (-not (Resolve-ExistingPath -Path $PostgresExecutable)) {
    $ValidationErrors.Add("postgres.exe not found: $PostgresExecutable")
}

if (-not (Resolve-ExistingPath -Path $PgData)) {
    $ValidationErrors.Add("Data directory not found: $PgData")
}
elseif (-not (Test-Path -LiteralPath (Join-Path $PgData "PG_VERSION"))) {
    $ValidationErrors.Add("PostgreSQL data directory is not initialized: $PgData")
}

if (-not (Test-Path -LiteralPath (Join-Path $PgData "postgresql.conf"))) {
    $ValidationErrors.Add("postgresql.conf not found: $($PgData)\postgresql.conf")
}

if (-not (Test-Path -LiteralPath (Join-Path $PgData "pg_hba.conf"))) {
    $ValidationErrors.Add("pg_hba.conf not found: $($PgData)\pg_hba.conf")
}

if ($ValidationErrors.Count -gt 0) {
    throw "PostgreSQL service prerequisites validation failed: $($ValidationErrors -join '; ')"
}

$PortListener = Get-NetTCPConnection -LocalPort $PgPort -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($PortListener) {
    Write-Log "Port $PgPort is currently listening by PID $($PortListener.OwningProcess)."
}

$ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($ExistingService) {
    Write-Log "Existing PostgreSQL service detected. Current state: $($ExistingService.Status)."

    $CurrentPgCtl = (Resolve-Path -LiteralPath $PgCtl).Path
    $CurrentDataDir = (Resolve-Path -LiteralPath $PgData).Path
    $ServiceImagePath = Get-ServiceImagePath -Name $ServiceName
    $ImagePathMatchesDeployment = Test-ServiceImageMatchesDeployment -ServiceImagePath $ServiceImagePath -CurrentPgCtl $CurrentPgCtl -CurrentDataDir $CurrentDataDir

    if (-not $ImagePathMatchesDeployment) {
        Write-Log "Service ImagePath does not match the current deployment. Re-registering the service..."
        Register-PostgreSQLService -PgCtl $PgCtl -PgData $PgData -PgPort $PgPort -ServiceName $ServiceName
        $ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    }
    elseif ($ExistingService.Status -eq "Running") {
        Write-Log "Service ImagePath matches the current deployment and the service is already running."
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
    }

    if ($ExistingService.Status -eq "StartPending") {
        Write-Log "Service is still starting. Waiting briefly..."
        $ExistingService = Wait-ForServiceState -Name $ServiceName -ExpectedStates @("Running", "Stopped", "Failed") -TimeoutSeconds 30
    }

    if ($ExistingService -and $ExistingService.Status -eq "Running") {
        Write-Log "Service reached Running state."
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
    }

    if ($ExistingService -and $ExistingService.Status -eq "Failed") {
        Write-Log "Service previously failed. Re-registering the service before retrying."
        Register-PostgreSQLService -PgCtl $PgCtl -PgData $PgData -PgPort $PgPort -ServiceName $ServiceName
        $ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    }
    elseif ($ExistingService -and $ExistingService.Status -eq "Stopped") {
        Write-Log "Service is stopped. Determining whether it can be started safely..."
        if ($PortListener) {
            throw "Configured port $PgPort is already in use by another process; service start is blocked."
        }
    }
    else {
        if ($PortListener) {
            throw "Configured port $PgPort is already in use by another process; service start is blocked."
        }
    }
}
else {
    Write-Log "No existing PostgreSQL service was found. Registering a new service."
    Register-PostgreSQLService -PgCtl $PgCtl -PgData $PgData -PgPort $PgPort -ServiceName $ServiceName
    $ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
}

Write-Log "Starting PostgreSQL Windows service..."

try {
    Start-Service -Name $ServiceName -ErrorAction Stop
}
catch {
    Write-ServiceFailureDetails -ServiceName $ServiceName -PgCtl $PgCtl -PgData $PgData -PgLog $PgLog -PgPort $PgPort -Reason $_.Exception.Message
    throw "PostgreSQL Windows service could not be started: $($_.Exception.Message)"
}

$Service = Wait-ForServiceState -Name $ServiceName -ExpectedStates @("Running", "Stopped", "Failed") -TimeoutSeconds 60
if (-not $Service) {
    Write-ServiceFailureDetails -ServiceName $ServiceName -PgCtl $PgCtl -PgData $PgData -PgLog $PgLog -PgPort $PgPort -Reason "Service did not report a terminal state within the timeout."
    throw "PostgreSQL Windows service did not reach a usable state."
}

if ($Service.Status -ne "Running") {
    Write-ServiceFailureDetails -ServiceName $ServiceName -PgCtl $PgCtl -PgData $PgData -PgLog $PgLog -PgPort $PgPort -Reason "Service ended in state $($Service.Status)."
    throw "PostgreSQL Windows service ended in state $($Service.Status)."
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
    Write-ServiceFailureDetails -ServiceName $ServiceName -PgCtl $PgCtl -PgData $PgData -PgLog $PgLog -PgPort $PgPort -Reason "PostgreSQL is not listening on port $PgPort after the service started."
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
