
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING MYSQL WINDOWS SERVICE"
Write-Host "====================================="
Write-Host ""

$ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$ConfigFile = "$ROOT\config\windows\mysql.conf"
$BaseDir    = "$ROOT\databases\mysql\server"
$DataDir    = "$ROOT\databases\mysql\data"
$Mysqld     = "$BaseDir\bin\mysqld.exe"
$MyIni      = "$ROOT\databases\mysql\my.ini"

$ServiceName = "MySQLAutomation"

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

if (!(Test-Path $Mysqld)) {
    throw "mysqld.exe not found: $Mysqld"
}

if (!(Test-Path $DataDir)) {
    throw "MySQL data directory not found: $DataDir"
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
# CREATE MY.INI
# =====================================

Write-Host "Creating MySQL configuration file..."

$BaseDirConfig = $BaseDir.Replace("\", "/")
$DataDirConfig = $DataDir.Replace("\", "/")

$MyIniContent = @"
[mysqld]
basedir=$BaseDirConfig
datadir=$DataDirConfig
port=$MySQLPort
bind-address=$MySQLHost
"@

Set-Content `
    -Path $MyIni `
    -Value $MyIniContent `
    -Encoding ASCII

if (!(Test-Path $MyIni)) {
    throw "Failed to create my.ini"
}

Write-Host "Configuration : $MyIni"

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
# STOP PROJECT MYSQL INSTANCE
# =====================================

Write-Host "Checking MySQL instance on configured port $MySQLPort..."

$PortConnection = Get-NetTCPConnection `
    -LocalPort $MySQLPort `
    -State Listen `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($PortConnection) {

    $ProcessId = $PortConnection.OwningProcess

    Write-Host "Process found on configured port."
    Write-Host "Port       : $MySQLPort"
    Write-Host "Process ID : $ProcessId"

    $Process = Get-Process `
        -Id $ProcessId `
        -ErrorAction SilentlyContinue

    if ($Process -and $Process.ProcessName -eq "mysqld") {

        Write-Host "Stopping project MySQL process PID: $ProcessId"

        Stop-Process `
            -Id $ProcessId `
            -Force

        Start-Sleep -Seconds 3

    }
    else {

        throw "Port $MySQLPort is occupied by a non-MySQL process."
    }
}
else {

    Write-Host "No standalone MySQL instance found on port $MySQLPort."
}

# =====================================
# REMOVE OLD SERVICE
# =====================================

if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {

    Write-Host "Removing existing MySQL service..."

    & $Mysqld --remove $ServiceName

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to remove existing MySQL service"
    }

    Start-Sleep -Seconds 3
}

# =====================================
# INSTALL MYSQL SERVICE
# =====================================

Write-Host ""
Write-Host "Installing MySQL Windows Service..."

& $Mysqld `
    "--defaults-file=$MyIni" `
    --install $ServiceName

if ($LASTEXITCODE -ne 0) {
    throw "MySQL Windows Service installation failed. Exit code: $LASTEXITCODE"
}

# =====================================
# VALIDATE SERVICE EXISTS
# =====================================

$InstalledService = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if (-not $InstalledService) {
    throw "MySQL service was not created"
}

# =====================================
# CONFIGURE AUTO START
# =====================================

& sc.exe config $ServiceName start= auto

if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure automatic startup"
}

# =====================================
# START SERVICE
# =====================================

Write-Host ""
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
