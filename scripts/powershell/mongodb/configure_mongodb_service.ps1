
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING MONGODB WINDOWS SERVICE"
Write-Host "====================================="
Write-Host ""

# =====================================
# PROJECT ROOT
# =====================================

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$MongoHome = "$PROJECT_ROOT\databases\mongodb"
$MongodExe = "$MongoHome\server\bin\mongod.exe"
$DataPath  = "$MongoHome\data"
$LogDir    = "$MongoHome\logs"
$LogPath   = "$LogDir\mongodb.log"

$ServiceName = "MongoDBAutomation"

# =====================================
# READ CONFIG
# =====================================

$ConfigFile = "$PROJECT_ROOT\config\windows\mongodb.conf"

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

$MongoHost = $Config["MONGODB_HOST"]
$MongoPort = $Config["MONGODB_PORT"]

if (-not $MongoHost) {
    throw "MONGODB_HOST not found in mongodb.conf"
}

if (-not $MongoPort) {
    throw "MONGODB_PORT not found in mongodb.conf"
}

Write-Host "Project Root : $PROJECT_ROOT"
Write-Host "MongoDB      : $MongodExe"
Write-Host "Data Path    : $DataPath"
Write-Host "Log Path     : $LogPath"
Write-Host "Host         : $MongoHost"
Write-Host "Port         : $MongoPort"
Write-Host "Service      : $ServiceName"
Write-Host ""

# =====================================
# VALIDATE MONGODB
# =====================================

if (!(Test-Path $MongodExe)) {
    throw "mongod.exe not found: $MongodExe"
}

if (!(Test-Path $DataPath)) {
    New-Item `
        -ItemType Directory `
        -Path $DataPath `
        -Force | Out-Null
}

if (!(Test-Path $LogDir)) {
    New-Item `
        -ItemType Directory `
        -Path $LogDir `
        -Force | Out-Null
}

# =====================================
# STOP EXISTING SERVICE
# =====================================

$ExistingService = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if ($ExistingService) {

    Write-Host "Existing MongoDB service found."

    if ($ExistingService.Status -eq "Running") {

        Write-Host "Stopping existing MongoDB service..."

        Stop-Service `
            -Name $ServiceName `
            -Force

        Start-Sleep -Seconds 3
    }
}

# =====================================
# STOP STANDALONE MONGOD PROCESS
# =====================================

Write-Host "Checking standalone MongoDB processes..."

Get-Process mongod -ErrorAction SilentlyContinue |
ForEach-Object {

    Write-Host "Stopping mongod process PID: $($_.Id)"

    Stop-Process `
        -Id $_.Id `
        -Force
}

Start-Sleep -Seconds 3

# =====================================
# REMOVE OLD SERVICE
# =====================================

if ($ExistingService) {

    Write-Host "Removing existing MongoDB service..."

    & sc.exe delete $ServiceName | Out-Null

    Start-Sleep -Seconds 3
}

# =====================================
# INSTALL MONGODB SERVICE
# =====================================

Write-Host ""
Write-Host "Installing MongoDB Windows Service..."

& $MongodExe `
    --dbpath $DataPath `
    --logpath $LogPath `
    --bind_ip $MongoHost `
    --port $MongoPort `
    --serviceName $ServiceName `
    --serviceDisplayName "MongoDB Automation Service" `
    --install

if ($LASTEXITCODE -ne 0) {
    throw "MongoDB service installation failed"
}

# =====================================
# CONFIGURE AUTO START
# =====================================

& sc.exe config $ServiceName start= auto | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure MongoDB service auto start"
}

# =====================================
# START SERVICE
# =====================================

Write-Host "Starting MongoDB Windows Service..."

Start-Service -Name $ServiceName

# =====================================
# WAIT FOR SERVICE
# =====================================

$Started = $false

for ($i = 1; $i -le 30; $i++) {

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if ($Service.Status -eq "Running") {
        $Started = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $Started) {
    throw "MongoDB Windows Service failed to start"
}

# =====================================
# VALIDATE PORT
# =====================================

$PortStarted = $false

for ($i = 1; $i -le 30; $i++) {

    $PortCheck = netstat -ano | Select-String ":$MongoPort"

    if ($PortCheck) {
        $PortStarted = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $PortStarted) {
    throw "MongoDB is not listening on port $MongoPort"
}

Write-Host ""
Write-Host "====================================="
Write-Host "MONGODB WINDOWS SERVICE CONFIGURED"
Write-Host "====================================="
Write-Host ""
Write-Host "Service : $ServiceName"
Write-Host "Status  : Running"
Write-Host "Startup : Automatic"
Write-Host "Host    : $MongoHost"
Write-Host "Port    : $MongoPort"
Write-Host ""

exit 0
