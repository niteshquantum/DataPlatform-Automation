
$ErrorActionPreference = "Stop"

$ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$configFile = "$ROOT\config\windows\mysql.conf"

if (!(Test-Path $configFile)) {
    throw "Config file not found: $configFile"
}

# =====================================
# READ CONFIG
# =====================================

$config = @{}

Get-Content $configFile | ForEach-Object {

    if ($_ -match "^([^#][^=]*)=(.*)$") {

        $key = $matches[1].Trim()
        $value = $matches[2].Trim()

        $config[$key] = $value
    }
}

$hostName = $config["MYSQL_HOST"]
$port     = $config["MYSQL_PORT"]
$database = $config["MYSQL_DB"]
$user     = $config["MYSQL_USER"]
$password = $config["MYSQL_PASSWORD"]

$mysqlExe = "$ROOT\databases\mysql\server\bin\mysql.exe"

$globalDirectory = "C:\ProgramData\DatabaseAutomation\mysql"
$globalCommand   = "$globalDirectory\mysql.cmd"

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING GLOBAL MYSQL COMMAND"
Write-Host "====================================="
Write-Host ""

# =====================================
# VALIDATE MYSQL CLIENT
# =====================================

if (!(Test-Path $mysqlExe)) {
    throw "mysql.exe not found: $mysqlExe"
}

Write-Host "MySQL Client : $mysqlExe"
Write-Host "Host         : $hostName"
Write-Host "Port         : $port"
Write-Host "Database     : $database"
Write-Host "User         : $user"

# =====================================
# CREATE GLOBAL DIRECTORY
# =====================================

if (!(Test-Path $globalDirectory)) {

    New-Item `
        -ItemType Directory `
        -Path $globalDirectory `
        -Force | Out-Null
}

# =====================================
# CREATE MYSQL COMMAND
# =====================================

$commandContent = @"
@echo off

"$mysqlExe" ^
--host="$hostName" ^
--port="$port" ^
--user="$user" ^
--password="$password" ^
"$database" %*
"@

Set-Content `
    -Path $globalCommand `
    -Value $commandContent `
    -Encoding ASCII

# =====================================
# ADD DIRECTORY TO SYSTEM PATH
# =====================================

$machinePath = [Environment]::GetEnvironmentVariable(
    "Path",
    "Machine"
)

$pathEntries = $machinePath -split ";"

if ($pathEntries -notcontains $globalDirectory) {

    Write-Host ""
    Write-Host "Adding MySQL command to System PATH..."

    $newPath = $machinePath.TrimEnd(";") + ";" + $globalDirectory

    [Environment]::SetEnvironmentVariable(
        "Path",
        $newPath,
        "Machine"
    )
}
else {

    Write-Host ""
    Write-Host "MySQL command already exists in System PATH"
}

# =====================================
# VALIDATE GLOBAL COMMAND FILE
# =====================================

if (!(Test-Path $globalCommand)) {
    throw "Global MySQL command creation failed"
}

Write-Host ""
Write-Host "====================================="
Write-Host "GLOBAL MYSQL CONFIGURED SUCCESSFULLY"
Write-Host "====================================="
Write-Host ""
Write-Host "Command:"
Write-Host "mysql"
Write-Host ""
Write-Host "Open a NEW CMD window before testing."
Write-Host ""

