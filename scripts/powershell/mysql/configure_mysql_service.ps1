
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING MYSQL WINDOWS SERVICE"
Write-Host "====================================="
Write-Host ""

# =====================================
# PROJECT ROOT
# =====================================

$ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$ConfigFile = "$ROOT\config\windows\mysql.conf"

$BaseDir = "$ROOT\databases\mysql\server"
$DataDir = "$ROOT\databases\mysql\data"

$Mysqld = "$BaseDir\bin\mysqld.exe"

$ServiceName = "MySQLAutomation"

# =====================================
# READ CONFIG
# =====================================

if (!(Test-Path $ConfigFile)) {
    throw "Config file not found: $ConfigFile"
}

$Config = @{}

Get-Content $ConfigFile | ForEach-Object {

    $Line = $_.Trim()

    if (
        $Line -and
        -not $Line.StartsWith("#") -and
        $Line.Contains("=")
    ) {

        $Key, $Value = $Line.Split("=", 2)

        $Config[$Key.Trim()] = $Value.Trim()
    }
}

$MySQLHost = $Config["MYSQL_HOST"]
$MySQLPort = $Config["MYSQL_PORT"]

if (-not $MySQLHost) {
    throw "MYSQL_HOST not found in mysql.conf"
}

if (-not $MySQLPort) {
    throw "MYSQL_PORT not found in mysql.conf"
}

Write-Host "Project Root : $ROOT"
Write-Host "MySQL        : $Mysqld"
Write-Host "BaseDir      : $BaseDir"
Write-Host "DataDir      : $DataDir"
Write-Host "Host         : $MySQLHost"
Write-Host "Port         : $MySQLPort"
Write-Host "Service      : $ServiceName"
Write-Host ""

# =====================================
# VALIDATE
# =====================================

if (!(Test-Path $Mysqld)) {
    throw "mysqld.exe not found: $Mysqld"
}

if (!(Test-Path $DataDir)) {
    throw "MySQL data directory not found: $DataDir"
}

# =====================================
# STOP EXISTING SERVICE
# =====================================

$ExistingService = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if ($ExistingService) {

    Write-Host "Existing MySQL service found."

    if ($ExistingService.Status -eq "Running") {

        Write-Host "Stopping existing MySQL service..."

        Stop-Service `
            -Name $ServiceName `
            -Force

        Start-Sleep -Seconds 3
    }
}

# =====================================
# STOP STANDALONE MYSQL PROCESS
# =====================================

Write-Host "Checking standalone MySQL processes..."

Get-Process mysqld -ErrorAction SilentlyContinue |
ForEach-Object {

    Write-Host "Stopping mysqld process PID: $($_.Id)"

    Stop-Process `
        -Id $_.Id `
        -Force
}

Start-Sleep -Seconds 3

# =====================================
# REMOVE OLD SERVICE
# =====================================

if ($ExistingService) {

    Write-Host "Removing existing MySQL service..."

    & $Mysqld `
        --remove $ServiceName

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to remove existing MySQL service"
    }

    Start-Sleep -Seconds 3
}

# =====================================
# INSTALL MYSQL WINDOWS SERVICE
# =====================================

Write-Host ""
Write-Host "Installing MySQL Windows Service..."

& $Mysqld `
    --install $ServiceName `
    --basedir="$BaseDir" `
    --datadir="$DataDir" `
    --port=$MySQLPort

if ($LASTEXITCODE -ne 0) {
    throw "MySQL Windows Service installation failed"
}

# =====================================
# CONFIGURE AUTOMATIC START
# =====================================

& sc.exe config $ServiceName start= auto | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure MySQL service automatic startup"
}

# =====================================
# START MYSQL SERVICE
# =====================================

Write-Host "Starting MySQL Windows Service..."

Start-Service -Name $ServiceName

# =====================================
# WAIT FOR SERVICE
# =====================================

$ServiceStarted = $false

for ($i = 1; $i -le 60; $i++) {

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if ($Service -and $Service.Status -eq "Running") {

        $ServiceStarted = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $ServiceStarted) {
    throw "MySQL Windows Service failed to start"
}

# =====================================
# WAIT FOR PORT
# =====================================

$PortStarted = $false

for ($i = 1; $i -le 60; $i++) {

    $PortCheck = Get-NetTCPConnection `
        -LocalPort $MySQLPort `
        -State Listen `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($PortCheck) {

        $PortStarted = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $PortStarted) {
    throw "MySQL is not listening on port $MySQLPort"
}

Write-Host ""
Write-Host "====================================="
Write-Host "MYSQL WINDOWS SERVICE CONFIGURED"
Write-Host "====================================="
Write-Host ""
Write-Host "Service : $ServiceName"
Write-Host "Status  : Running"
Write-Host "Startup : Automatic"
Write-Host "Host    : $MySQLHost"
Write-Host "Port    : $MySQLPort"
Write-Host ""

exit 0
