# ============================================================
# remove_sqlserver.ps1
# SQL Server Instance Removal
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

    return ($Line -split "=", 2)[1].Trim()
}

function Get-SqlCmdPath {

    if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
        return (Get-Command sqlcmd).Source
    }

    $SqlCmd = Get-ChildItem `
        "C:\Program Files\Microsoft SQL Server" `
        -Recurse `
        -Filter "sqlcmd.exe" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($SqlCmd) {
        return $SqlCmd.FullName
    }

    return $null
}

try {

    Write-Log "Starting SQL Server instance removal"

    # --------------------------------------------------------
    # Administrator Validation
    # --------------------------------------------------------

    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)

    if (-not $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )) {
        throw "Administrator privileges required"
    }

    # --------------------------------------------------------
    # Load Configuration
    # --------------------------------------------------------

    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent

    $ConfigFile = Join-Path $ProjectRoot "config\sqlserver.conf"

    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }

    $InstanceName = Get-ConfigValue $ConfigFile "INSTANCE_NAME"
    $Port         = Get-ConfigValue $ConfigFile "PORT"
    $Installer    = Get-ConfigValue $ConfigFile "INSTALLER_NAME"
    $DownloadDir  = Get-ConfigValue $ConfigFile "DOWNLOAD_DIR"

    $ServiceName = if ($InstanceName -eq "MSSQLSERVER") {
        "MSSQLSERVER"
    }
    else {
        "MSSQL`$$InstanceName"
    }

    # --------------------------------------------------------
    # Stop Service
    # --------------------------------------------------------

    $Service = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if ($Service) {

        if ($Service.Status -ne "Stopped") {

            Write-Log "Stopping service $ServiceName"

            Stop-Service `
                -Name $ServiceName `
                -Force `
                -ErrorAction Stop

            $Timeout = 60
            $Elapsed = 0

            while ($Elapsed -lt $Timeout) {

                $Status = (
                    Get-Service $ServiceName
                ).Status

                if ($Status -eq "Stopped") {
                    break
                }

                Start-Sleep -Seconds 5
                $Elapsed += 5
            }
        }
    }

    # --------------------------------------------------------
    # Locate SQL Setup
    # --------------------------------------------------------

    Write-Log "Locating SQL Server setup executable"

    $SetupExe = Get-ChildItem `
        "C:\Program Files\Microsoft SQL Server" `
        -Recurse `
        -Filter "setup.exe" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $SetupExe) {
        throw "Unable to locate SQL Server setup.exe"
    }

    # --------------------------------------------------------
    # Uninstall Instance
    # --------------------------------------------------------

    Write-Log "Uninstalling instance: $InstanceName"

    $Arguments =
        "/ACTION=Uninstall " +
        "/FEATURES=SQLENGINE " +
        "/INSTANCENAME=$InstanceName " +
        "/Q " +
        "/IACCEPTSQLSERVERLICENSETERMS"

    $Process = Start-Process `
        -FilePath $SetupExe.FullName `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru

    if ($Process.ExitCode -ne 0 -and $Process.ExitCode -ne 3010) {
        throw "Uninstall failed. ExitCode=$($Process.ExitCode)"
    }

    Write-Log "Instance uninstall completed"

    # --------------------------------------------------------
    # Remove Instance-Specific Registry Keys
    # --------------------------------------------------------

    $RegistryRoot =
        "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"

    $InstanceRegistry = Get-ChildItem `
        $RegistryRoot `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.PSChildName -match "^MSSQL\d+\.$InstanceName$"
        } |
        Select-Object -First 1

    if ($InstanceRegistry) {

        Write-Log "Removing instance registry key"

        Remove-Item `
            -Path $InstanceRegistry.PSPath `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }

    # --------------------------------------------------------
    # Remove Installer Artifact
    # --------------------------------------------------------

    $InstallerPath = Join-Path `
        $ProjectRoot `
        "$DownloadDir\$Installer"

    if (Test-Path $InstallerPath) {

        Write-Log "Removing installer artifact"

        Remove-Item `
            -Path $InstallerPath `
            -Force `
            -ErrorAction Stop
    }

    # --------------------------------------------------------
    # Validation - Service Removed
    # --------------------------------------------------------

    Write-Log "Validating service removal"

    $ServiceCheck = Get-Service `
        -Name $ServiceName `
        -ErrorAction SilentlyContinue

    if ($ServiceCheck) {
        throw "Service still exists: $ServiceName"
    }

    # --------------------------------------------------------
    # Validation - Registry Removed
    # --------------------------------------------------------

    $RegistryCheck = Get-ChildItem `
        $RegistryRoot `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.PSChildName -match "^MSSQL\d+\.$InstanceName$"
        }

    if ($RegistryCheck) {
        throw "Instance registry still exists"
    }

    # --------------------------------------------------------
    # Validation - SQL Connectivity Failure
    # --------------------------------------------------------

    $SqlCmd = Get-SqlCmdPath

    if ($SqlCmd) {

        & $SqlCmd `
            -S "localhost,$Port" `
            -E `
            -Q "SELECT 1" `
            2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            throw "SQL connectivity still available after uninstall"
        }
    }

    Write-Log "SQL connectivity validation passed"

    Write-Log "Instance removal validated successfully"

    exit 0
}
catch {

    Write-Error $_.Exception.Message

    exit 1
}