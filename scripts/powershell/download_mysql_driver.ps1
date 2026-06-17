$ErrorActionPreference = "Stop"

# =====================================

# PROJECT ROOT

# =====================================

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

# =====================================

# CONFIG FILE

# =====================================

$ConfigFile = Join-Path $ProjectRoot "config\mysql.conf"

if (!(Test-Path $ConfigFile)) {
Write-Error "Config file not found: $ConfigFile"
exit 1
}

# =====================================

# READ CONFIG

# =====================================

$Config = @{}

Get-Content $ConfigFile | ForEach-Object {


    if ($_ -match "=") {

        $Key, $Value = $_ -split "=", 2

        $Config[$Key.Trim()] = $Value.Trim()
    }


}

$DriverVersion = $Config["MYSQL_DRIVER_VERSION"]

if ([string]::IsNullOrWhiteSpace($DriverVersion)) {
Write-Error "MYSQL_DRIVER_VERSION not found in mysql.conf"
exit 1
}

# =====================================

# DRIVER DIRECTORY

# =====================================

$DriverDir = Join-Path $ProjectRoot "tools\drivers"

if (!(Test-Path $DriverDir)) {
New-Item -ItemType Directory -Path $DriverDir -Force | Out-Null
}

# =====================================

# DRIVER FILE

# =====================================

$JarFile = Join-Path $DriverDir "mysql-connector-j-$DriverVersion.jar"

if (Test-Path $JarFile) {
Write-Host "MySQL Connector already exists."
exit 0
}

# =====================================

# DOWNLOAD URL

# =====================================

$DownloadUrl = "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/$DriverVersion/mysql-connector-j-$DriverVersion.jar"

Write-Host "Downloading MySQL Connector Version $DriverVersion ..."
Write-Host "URL : $DownloadUrl"

Invoke-WebRequest -Uri $DownloadUrl -OutFile $JarFile -UseBasicParsing

# =====================================

# VALIDATE DOWNLOAD

# =====================================

if (!(Test-Path $JarFile)) {
Write-Error "MySQL Driver download failed."
exit 1
}

Write-Host "MySQL Driver downloaded successfully."
