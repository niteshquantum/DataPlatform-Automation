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
# NORMALIZE EXPECTED PATHS
# =====================================

$ExpectedMongodPath = [System.IO.Path]::GetFullPath($MongodExe)

# =====================================
# CHECK IF ALREADY RUNNING
# =====================================

Write-Host "Checking if MongoDB is already running on port $MongoPort..."

$Listener = Get-NetTCPConnection `
    -LocalPort $MongoPort `
    -State Listen `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($Listener) {

    $OwnerProcessId = $Listener.OwningProcess

    Write-Host ""
    Write-Host "Port $MongoPort is in LISTEN state"
    Write-Host "Listener PID : $OwnerProcessId"

    $OwnerProcessInfo = Get-CimInstance `
        Win32_Process `
        -Filter "ProcessId=$OwnerProcessId" `
        -ErrorAction SilentlyContinue

    $IsProjectOwned = $false
    $ActualPath = $null

    if ($OwnerProcessInfo -and $OwnerProcessInfo.ExecutablePath) {
        $ActualPath = [System.IO.Path]::GetFullPath($OwnerProcessInfo.ExecutablePath)
        Write-Host "Listener Process : $($OwnerProcessInfo.Name)"
        Write-Host "Listener Path    : $ActualPath"
    }

    # =====================================
    # DURABLE SERVICE OWNERSHIP CHECK (CROSS-WORKSPACE)
    # =====================================

    if (-not $IsProjectOwned) {

        $ServiceName = "MongoDBAutomation"

        $ServiceInfo = Get-CimInstance `
            Win32_Service `
            -Filter "Name='$ServiceName'" `
            -ErrorAction SilentlyContinue

        if ($ServiceInfo) {

            $ServicePathName = $ServiceInfo.PathName.Trim()
            $ServiceExe = $ServicePathName

            if ($ServicePathName.StartsWith('"')) {
                $EndQuote = $ServicePathName.IndexOf('"', 1)
                if ($EndQuote -ne -1) {
                    $ServiceExe = $ServicePathName.Substring(1, $EndQuote - 1)
                }
            }
            else {
                $ServiceExe = $ServicePathName.Split(' ')[0]
            }

            if ($ActualPath) {
                $ServiceExe = [System.IO.Path]::GetFullPath($ServiceExe)
                if ($ActualPath.Equals($ServiceExe, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $IsProjectOwned = $true
                }
            }

            if (-not $IsProjectOwned -and $OwnerProcessId -eq $ServiceInfo.ProcessId) {
                $IsProjectOwned = $true
            }
        }
    }

    # =====================================
    # CURRENT WORKSPACE FALLBACK
    # =====================================

    if (-not $IsProjectOwned -and $ActualPath) {
        if ($ActualPath.Equals($ExpectedMongodPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $IsProjectOwned = $true
        }
    }

    if (-not $IsProjectOwned) {

        Write-Host ""
        Write-Host "======================================="
        Write-Host "FOREIGN PROCESS LISTENING ON PORT $MongoPort"
        Write-Host "======================================="
        Write-Host "Expected (current workspace) : $ExpectedMongodPath"

        if ($ServiceInfo) {
            Write-Host "Durable service              : $ServiceName"
            Write-Host "Service path                 : $($ServiceInfo.PathName)"
        }

        if ($OwnerProcessInfo) {
            Write-Host "Actual process               : $($OwnerProcessInfo.ExecutablePath)"
            Write-Host "PID                          : $($OwnerProcessInfo.ProcessId)"
            Write-Host "Name                         : $($OwnerProcessInfo.Name)"
        }
        else {
            Write-Host "Actual process               : Unable to resolve executable path"
            Write-Host "PID                          : $OwnerProcessId"
        }

        Write-Host ""
        Write-Host "Action   : Aborting start. Foreign process will not be altered."
        Write-Host "======================================="
        Write-Host ""

        throw "Foreign process detected on MongoDB port $MongoPort. Expected project-managed mongod at: $ExpectedMongodPath"
    }

    Write-Host ""
    Write-Host "Project-managed MongoDB already running on port $MongoPort"
    Write-Host ""

    exit 0
}

# =====================================
# CHECK FOR DURABLE SERVICE (FRESH WORKSPACE)
# =====================================

$ServiceName = "MongoDBAutomation"

$ServiceInfo = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if ($ServiceInfo) {

    Write-Host ""
    Write-Host "Durable managed service detected: $ServiceName"
    Write-Host "Service status : $($ServiceInfo.Status)"

    if ($ServiceInfo.Status -eq "Running") {
        Write-Host "Service reports running but port $MongoPort is not listening."
        Write-Host "Waiting briefly for port to become ready..."
        Start-Sleep -Seconds 5

        $PortCheck = netstat -ano | Select-String ":$MongoPort"
        if ($PortCheck) {
            Write-Host "Port $MongoPort is now listening."
            exit 0
        }

        throw "Managed MongoDB service is running but port $MongoPort is not reachable."
    }

    if ($ServiceInfo.Status -ne "Stopped") {
        throw "Managed MongoDB service '$ServiceName' is in unexpected state: $($ServiceInfo.Status). Expected Stopped."
    }

    Write-Host "Starting managed MongoDB service..."
    Write-Host ""

    Start-Service `
        -Name $ServiceName `
        -ErrorAction Stop

    Write-Host "Waiting for MongoDB service to start..."

    $ServiceStarted = $false

    for ($i = 1; $i -le 30; $i++) {

        $Svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($Svc -and $Svc.Status -eq "Running") {
            $ServiceStarted = $true
            break
        }

        Start-Sleep -Seconds 1
    }

    if (-not $ServiceStarted) {

        $Svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

        if ($Svc -and $Svc.Status -ne "Running") {
            throw "Managed MongoDB service failed to start. Current status: $($Svc.Status)"
        }

        throw "Managed MongoDB service did not report Running within timeout."
    }

    Write-Host ""
    Write-Host "Managed MongoDB service started successfully."
    Write-Host ""

    # Wait for port
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
        throw "Managed MongoDB service started but port $MongoPort is not listening."
    }

    Write-Host "==================================="
    Write-Host "MONGODB STARTED SUCCESSFULLY (SERVICE)"
    Write-Host "Port : $MongoPort"
    Write-Host "==================================="
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

Start-Process `
    -FilePath $MongodExe `
    -ArgumentList @(
        "--dbpath", $DataPath,
        "--logpath", $LogPath,
        "--bind_ip", $MongoHost,
        "--port", $MongoPort
    ) `
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
