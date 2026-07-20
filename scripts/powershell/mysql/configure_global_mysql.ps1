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

function New-MySqlWrapper {
    param(
        [string]$Path,
        [string]$DatabaseName
    )

    $commandContent = @"
@echo off

"$mysqlExe" ^
--host="$hostName" ^
--port="$port" ^
--user="$user" ^
--password="$password" ^
"$DatabaseName" %*
"@

    Set-Content -Path $Path -Value $commandContent -Encoding ASCII
}

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING GLOBAL MYSQL COMMAND"
Write-Host "====================================="
Write-Host ""

if (!(Test-Path $mysqlExe)) {
    throw "mysql.exe not found: $mysqlExe"
}

Write-Host "MySQL Client : $mysqlExe"
Write-Host "Host         : $hostName"
Write-Host "Port         : $port"
Write-Host "Database     : $database"
Write-Host "User         : $user"

if (!(Test-Path $globalDirectory)) {
    New-Item -ItemType Directory -Path $globalDirectory -Force | Out-Null
}

$safeDatabaseName = ($database -replace '[^A-Za-z0-9]', '_')
$instanceWrapperName = "mysql_${safeDatabaseName}_${port}.cmd"
$instanceWrapperPath = Join-Path $globalDirectory $instanceWrapperName

Write-Host "Creating instance-aware wrapper: $instanceWrapperName"
New-MySqlWrapper -Path $instanceWrapperPath -DatabaseName $database

Write-Host "Updating default mysql wrapper for current configuration"
New-MySqlWrapper -Path $globalCommand -DatabaseName $database

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$pathEntries = $machinePath -split ";" |
    Where-Object {
        $_ -and
        $_.Trim().TrimEnd("\") -ne $globalDirectory.TrimEnd("\")
    }

$newPath = $globalDirectory + ";" + ($pathEntries -join ";")
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

Write-Host ""
Write-Host "MySQL global command directory moved to beginning of System PATH"

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
Write-Host "Instance wrapper:"
Write-Host $instanceWrapperName
Write-Host ""
Write-Host "Open a NEW CMD window before testing."
Write-Host ""

exit 0
