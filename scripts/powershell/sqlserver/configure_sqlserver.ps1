# ============================================================
# configure_sqlserver.ps1
# SQL Server Network and Authentication Configuration
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

function Get-SqlCmdPath {

    $SqlCmd = Get-ChildItem `
        "C:\Program Files\Microsoft SQL Server" `
        -Recurse `
        -Filter "sqlcmd.exe" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (!$SqlCmd) {
        throw "sqlcmd.exe not found"
    }

    return $SqlCmd.FullName
}

try {

    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent

    $ConfigFile = Join-Path $ProjectRoot "config\sqlserver.conf"

    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found"
    }

    $InstanceName = Get-ConfigValue $ConfigFile "INSTANCE_NAME"
    $Port         = Get-ConfigValue $ConfigFile "PORT"
    $SAPassword   = Get-ConfigValue $ConfigFile "SA_PASSWORD"

    $ServiceName = if ($InstanceName -eq "MSSQLSERVER") {
        "MSSQLSERVER"
    }
    else {
        "MSSQL`$$InstanceName"
    }

    Write-Log "Searching SQL Server registry configuration"

    $RegBase = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"

    $InstanceKey = Get-ChildItem `
        $RegBase `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.PSChildName -match "^MSSQL\d+\.$InstanceName$"
        } |
        Select-Object -First 1

    if (!$InstanceKey) {
        throw "SQL Server registry key not found"
    }

    $AuthPath = "$($InstanceKey.PSPath)\MSSQLServer"

    if (Test-Path $AuthPath) {

        Set-ItemProperty `
            -Path $AuthPath `
            -Name LoginMode `
            -Value 2

        Write-Log "Mixed Mode Authentication enabled"
    }

    $TcpPath = "$($InstanceKey.PSPath)\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"

    if (Test-Path $TcpPath) {

        Set-ItemProperty `
            -Path $TcpPath `
            -Name TcpPort `
            -Value $Port

        Set-ItemProperty `
            -Path $TcpPath `
            -Name TcpDynamicPorts `
            -Value ""

        Write-Log "TCP Port configured: $Port"

        Write-Log "Dynamic Ports cleared"
    }

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if (!$Service) {
        throw "SQL Server service not found"
    }

    Write-Log "Restarting SQL Server service"

    Restart-Service `
        -Name $ServiceName `
        -Force

    Start-Sleep -Seconds 10

    $Timeout = 90
    $Elapsed = 0

    while ($Elapsed -lt $Timeout) {

        $Status = (
            Get-Service $ServiceName
        ).Status

        if ($Status -eq "Running") {
            break
        }

        Write-Log "Waiting for service startup ($Elapsed sec)"

        Start-Sleep -Seconds 5

        $Elapsed += 5
    }

    if ((Get-Service $ServiceName).Status -ne "Running") {
        throw "SQL Server service failed to start"
    }

    Write-Log "Enabling SA Login"

    $SqlCmd = Get-SqlCmdPath

    & $SqlCmd `
        -S "localhost,$Port" `
        -E `
        -Q "ALTER LOGIN SA ENABLE; ALTER LOGIN SA WITH PASSWORD='$SAPassword';" `
        2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to enable SA login"
    }

    Write-Log "SA Login enabled"

    Write-Log "Restarting service after authentication changes"

    Restart-Service `
        -Name $ServiceName `
        -Force

    Start-Sleep -Seconds 10

    $Elapsed = 0

    while ($Elapsed -lt $Timeout) {

        $Status = (
            Get-Service $ServiceName
        ).Status

        if ($Status -eq "Running") {
            break
        }

        Start-Sleep -Seconds 5

        $Elapsed += 5
    }

    if ((Get-Service $ServiceName).Status -ne "Running") {
        throw "Service failed after configuration"
    }


    Write-Log "Validating SQL Authentication"

& $SqlCmd `
    -S "localhost,$Port" `
    -U "SA" `
    -P $SAPassword `
    -Q "SELECT 1" `
    2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "SQL Authentication validation failed for SA login"
}

Write-Log "SQL Authentication validation successful"

    Write-Log "SQL Server configuration completed successfully"

    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}