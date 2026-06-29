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

Write-Host "PROJECT_ROOT : $PROJECT_ROOT"
Write-Host "Mongo Home   : $MongoHome"
Write-Host "mongod.exe   : $MongodExe"
Write-Host ""

# =====================================
# VALIDATE
# =====================================

if (!(Test-Path $MongodExe)) {
    throw "mongod.exe not found: $MongodExe"
}

if (!(Test-Path $DataPath)) {
    New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
}

if (!(Test-Path (Split-Path $LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
}

# =====================================
# START MONGODB
# =====================================

Start-Process `
    -FilePath $MongodExe `
    -ArgumentList @(
        "--dbpath", $DataPath,
        "--logpath", $LogPath,
        "--bind_ip", "127.0.0.1",
        "--port", "27018"
    ) `
    -WindowStyle Hidden

# =====================================
# WAIT FOR PORT
# =====================================

$Started = $false

for ($i = 1; $i -le 30; $i++) {

    $PortCheck = netstat -ano | Select-String ":27018"

    if ($PortCheck) {
        $Started = $true
        break
    }

    Start-Sleep -Seconds 1
}

if (-not $Started) {
    throw "MongoDB failed to start on port 27018."
}

Write-Host ""
Write-Host "==================================="
Write-Host "MONGODB STARTED SUCCESSFULLY"
Write-Host "Port : 27018"
Write-Host "==================================="
Write-Host ""

exit 0