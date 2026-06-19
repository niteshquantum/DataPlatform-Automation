# ============================================================
# stop_sqlserver.ps1
# SQL Server Service Shutdown
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

function Get-ConfigValue {
    param(
        [string]$FilePath,
        [string]$Key
    )

    $Line = Get-Content $FilePath |
            Where-Object { $_ -match "^$Key=" } |
            Select-Object -First 1

    if (-not $Line) {
        throw "Configuration key not found: $Key"
    }

    return ($Line -split "=",2)[1].Trim()
}

try {

    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent

    $ConfigFile = Join-Path $ProjectRoot "config\sqlserver.conf"

    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }

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

    if ($Service.Status -eq "Stopped") {
        Write-Log "Service already stopped"
        exit 0
    }

    Write-Log "Stopping service $ServiceName"

    Stop-Service `
        -Name $ServiceName `
        -Force

    $Timeout = 90
    $Elapsed = 0

    while ($Elapsed -lt $Timeout) {

        $Status = (
            Get-Service $ServiceName
        ).Status

        if ($Status -eq "Stopped") {
            break
        }

        Write-Log "Waiting for service shutdown ($Elapsed sec)"

        Start-Sleep -Seconds 5

        $Elapsed += 5
    }

    $FinalStatus = (
        Get-Service $ServiceName
    ).Status

    if ($FinalStatus -ne "Stopped") {
        throw "Service failed to stop"
    }

    Write-Log "SQL Server service stopped successfully"

    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}