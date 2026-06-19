# ============================================================
# install_windows.ps1
# SQL Server Silent Installation
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

    Write-Log "Starting SQL Server installation"

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Administrator privileges required"
    }

    Write-Log "Administrator validation passed"

    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent

    $ConfigFile = Join-Path $ProjectRoot "config\sqlserver.conf"

    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }

    $InstanceName = Get-ConfigValue $ConfigFile "INSTANCE_NAME"
    $Port         = Get-ConfigValue $ConfigFile "PORT"
    $SAPassword   = Get-ConfigValue $ConfigFile "SA_PASSWORD"
    $Installer    = Get-ConfigValue $ConfigFile "INSTALLER_NAME"

    $InstallerPath = Join-Path `
        $ProjectRoot `
        "databases\sqlserver\downloads\$Installer"

    if (!(Test-Path $InstallerPath)) {
        throw "Installer not found: $InstallerPath"
    }

    Write-Log "Installer found"

    $ServiceName = if ($InstanceName -eq "MSSQLSERVER") {
        "MSSQLSERVER"
    }
    else {
        "MSSQL`$$InstanceName"
    }

    $ExistingService = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if ($ExistingService) {
        Write-Log "SQL Server already installed"
        exit 0
    }

    $Arguments =
        "/ACTION=Install " +
        "/IACCEPTSQLSERVERLICENSETERMS " +
        "/QS " +
        "/FEATURES=SQLEngine " +
        "/INSTANCENAME=$InstanceName " +
        "/SECURITYMODE=SQL " +
        "/SAPWD=`"$SAPassword`" " +
        "/SQLSVCACCOUNT=`"NT AUTHORITY\SYSTEM`" " +
        "/SQLSYSADMINACCOUNTS=`"BUILTIN\Administrators`" " +
        "/TCPENABLED=1 " +
        "/NPENABLED=0 " +
        "/SQLSVCSTARTUPTYPE=Automatic " +
        "/UPDATEENABLED=FALSE"

    Write-Log "Installing SQL Server"

    $Process = Start-Process `
        -FilePath $InstallerPath `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru

    if ($Process.ExitCode -ne 0 -and $Process.ExitCode -ne 3010) {
        throw "SQL Server installation failed. ExitCode=$($Process.ExitCode)"
    }

    Write-Log "Installation completed"

    Set-Service `
        -Name $ServiceName `
        -StartupType Automatic

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if (!$Service) {
        throw "SQL Server service not found after installation"
    }

    Write-Log "Installation validation successful"

    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}