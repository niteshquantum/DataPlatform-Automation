# ============================================================
# start_sqlserver.ps1
# SQL Server Service Startup
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Get-ConfigValue {
    param(
        [string]$FilePath,
        [string]$Key
    )

    $line = Get-Content $FilePath |
            Where-Object { $_ -match "^$Key=" } |
            Select-Object -First 1

    if (-not $line) {
        throw "Configuration key not found: $Key"
    }

    return ($line -split "=",2)[1].Trim()
}

try {

    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent

    $ConfigFile = Join-Path $ProjectRoot "config\sqlserver.conf"

    $InstanceName = Get-ConfigValue `
        $ConfigFile `
        "INSTANCE_NAME"

    $ServiceName = if ($InstanceName -eq "MSSQLSERVER") {
        "MSSQLSERVER"
    }
    else {
        "MSSQL`$$InstanceName"
    }

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if (!$Service) {
        throw "Service not found: $ServiceName"
    }

    if ($Service.Status -eq "Running") {
        Write-Log "Service already running"
        exit 0
    }

    Write-Log "Starting service $ServiceName"

    Start-Service $ServiceName

    $Timeout = 90
    $Elapsed = 0

    while ($Elapsed -lt $Timeout) {

        $CurrentStatus = (
            Get-Service $ServiceName
        ).Status

        if ($CurrentStatus -eq "Running") {
            break
        }

        Write-Log "Waiting for service startup ($Elapsed sec)"

        Start-Sleep -Seconds 5

        $Elapsed += 5
    }

    $FinalStatus = (
        Get-Service $ServiceName
    ).Status

    if ($FinalStatus -ne "Running") {
        throw "Service failed to start"
    }

    Write-Log "SQL Server service running"

    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}