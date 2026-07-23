$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==================================="
Write-Host "STARTING MONGODB"
Write-Host "==================================="
Write-Host ""

# =====================================
# PROJECT ROOT
# =====================================

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$MongoHome = "$PROJECT_ROOT\databases\mongodb"
$MongodExe = "$MongoHome\server\bin\mongod.exe"
$DataPath = "$MongoHome\data"
$LogPath = "$MongoHome\logs\mongodb.log"

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
$MongoAuthEnabled = $Config["MONGODB_AUTHORIZATION_ENABLED"] -eq "true"

if (-not $MongoPort) {
    throw "MONGODB_PORT not found in mongodb.conf"
}

Write-Host "PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "Mongo Home   : $MongoHome"
Write-Host "mongod.exe   : $MongodExe"
Write-Host "Host         : $MongoHost"
Write-Host "Port         : $MongoPort"
Write-Host ""

# =====================================
# CHECK IF ALREADY RUNNING
# =====================================

$AlreadyRunning = netstat -ano | Select-String ":$MongoPort"

if ($AlreadyRunning) {

    Write-Host ""
    Write-Host "MongoDB already running on port $MongoPort"
    Write-Host ""

    exit 0
}

# =====================================
# VALIDATE
# =====================================

if (!(Test-Path $MongodExe)) {
    throw "mongod.exe not found: $MongodExe"
}

if (!(Test-Path $DataPath)) {
    New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
}

$LogDir = Split-Path $LogPath

if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# =====================================
# START MONGODB
# =====================================

$MongoArguments = @(
    "--dbpath", $DataPath,
    "--logpath", $LogPath,
    "--bind_ip", $MongoHost,
    "--port", $MongoPort
)
if ($MongoAuthEnabled) { $MongoArguments += "--auth" }

Start-Process `
    -FilePath $MongodExe `
    -ArgumentList $MongoArguments `
    -WindowStyle Hidden

# =====================================
# WAIT FOR PORT
# =====================================

$Started = $false

for ($i = 1; $i -le 30; $i++) {

    $PortCheck = netstat -ano | Select-String ":$MongoPort"

    if ($PortCheck) {

        $Started = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $Started) {
    throw "MongoDB failed to start on port $MongoPort."
}

Write-Host ""
Write-Host "==================================="
Write-Host "MONGODB STARTED SUCCESSFULLY"
Write-Host "Port : $MongoPort"
Write-Host "==================================="
Write-Host ""

exit 0
