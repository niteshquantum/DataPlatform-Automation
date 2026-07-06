<#
.SYNOPSIS
    DataPlatform-Automation - Microsoft SQL Server Unattended Installation Module
.DESCRIPTION
    Performs fully unattended, idempotent installation of Microsoft SQL Server.
    Self-elevates via the SYSTEM-privileged scheduled task if not already running
    elevated, so Terraform/Jenkins can call this exact file unchanged.
.NOTES
    Target OS: Windows Server 2019 / 2022
    PowerShell Version: 5.1+
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# === ELEVATION AUTO-DISPATCH (do not remove) ===
# If this script is not already running inside the SYSTEM-privileged task,
# re-dispatch itself through it and exit with whatever exit code that run
# produced. This keeps everything in ONE file - no separate worker file.
if ($env:DPA_ELEVATED -ne "1") {
    $InvokeElevated = Join-Path $PSScriptRoot "common\invoke_elevated.ps1"
    if (-not (Test-Path -Path $InvokeElevated)) {
        throw "[FATAL] invoke_elevated.ps1 not found at: $InvokeElevated. Ensure the 'common' folder exists alongside the mssql scripts folder."
    }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $InvokeElevated -ScriptPath $PSCommandPath
    exit $LASTEXITCODE
}
# === END ELEVATION AUTO-DISPATCH ===

# Define strict relative paths based on repository freeze structure
$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$ConfigPath = Join-Path $PROJECT_ROOT "config\windows\mssql.conf"
$MediaDir = Join-Path $PROJECT_ROOT "databases\mssql\media"
$TrackingFile = Join-Path $MediaDir "mounted_drive.txt"
$TempDirectory = [System.IO.Path]::GetTempPath()
$TempConfigIni = Join-Path $TempDirectory "sql_setup_configuration.ini"
Write-Output "[INIT] Starting SQL Server unattended installation phase (elevated)..."

# 1. Hardened Media Chain Verification
if (-not (Test-Path -Path $TrackingFile)) {
    throw "[ERROR] Mount tracking state token file missing at: $TrackingFile"
}

$MountedDrive = (Get-Content -Path $TrackingFile -Raw).Trim()
if ([string]::IsNullOrEmpty($MountedDrive) -or -not (Test-Path -Path $MountedDrive)) {
    throw "[ERROR] Resolved system target device location path cannot be found or read: '$MountedDrive'"
}

$SetupPath = Join-Path $MountedDrive "setup.exe"
if (-not (Test-Path -Path $SetupPath)) {
    throw "[ERROR] Target installation media verification failed. Executable 'setup.exe' is completely missing from root of $MountedDrive"
}

$SetupFileObj = Get-Item -Path $SetupPath
if ($SetupFileObj.Extension -ne ".exe") {
    throw "[ERROR] Target file component identity conflict. Asset setup target is not a valid executable file structure."
}
Write-Output "[VALIDATION] Hardened media validation check completely successful. Ready to interface setup engine."

# 2. Read and Parse Corporate Configuration Map
if (-not (Test-Path -Path $ConfigPath)) {
    throw "[ERROR] Configuration matrix file not found at expected location: $ConfigPath"
}

Write-Output "[CONFIG] Loading configuration tokens from $ConfigPath"
$Config = @{}
Get-Content -Path $ConfigPath | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $Key, $Value = $_ -split '=', 2
    $Config[$Key.Trim()] = $Value.Trim()
}

# 3. Strict Pre-flight Enterprise Configuration Map Validation
$RequiredKeys = @(
    "MSSQL_INSTANCE",
    "MSSQL_PORT",
    "MSSQL_PASSWORD",
    "MSSQL_SVC_ACCOUNT",
    "MSSQL_VERSION"
)

foreach ($Key in $RequiredKeys) {
    if (-not $Config.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Config[$Key])) {
        throw "[ERROR] Required configuration key missing or empty within mssql.conf: '$Key'"
    }
}

$InstanceName = $Config['MSSQL_INSTANCE']
$InstancePort = $Config['MSSQL_PORT']
$SaPassword  = $Config['MSSQL_PASSWORD']
$SvcAccount = if ($Config.ContainsKey('MSSQL_SVC_ACCOUNT')) {
    $Config['MSSQL_SVC_ACCOUNT']
}
else {
    'NT AUTHORITY\SYSTEM'
}
$SqlVersion  = $Config['MSSQL_VERSION']

# 4. Registry Idempotency Bypass Check
Write-Output "[IDEMPOTENCY] Evaluating host machine setup state allocation mapping context..."
$RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
$IsAlreadyInstalled = $false

if (Test-Path -Path $RegistryKeyPath) {
    $InstalledInstances = Get-ItemProperty -Path $RegistryKeyPath -ErrorAction SilentlyContinue
    if ($InstalledInstances -and $InstalledInstances.PSObject.Properties[$InstanceName]) {
        $IsAlreadyInstalled = $true
    }
}

if ($IsAlreadyInstalled) {
    Write-Output "=========================================================================================="
    Write-Output "[IDEMPOTENCY] Match Detected. SQL Server Named Instance '$InstanceName' is already installed on this machine."
    Write-Output "[IDEMPOTENCY] Bypassing installation execution pipeline block cleanly."
    Write-Output "=========================================================================================="
    exit 0
}

# 5. Volatile Configuration Artifact Lifecycle Engine
try {
    Write-Output "[CONFIG-ENGINE] Generating dynamic installation configuration context..."

    $IniContents = @(
        "[OPTIONS]",
        "ACTION=""Install""",
        "FEATURES=SQLENGINE",
        "QUIET=""True""",
        "IACCEPTSQLSERVERLICENSETERMS=""True""",
        "INSTANCENAME=""$InstanceName""",
        "SQLSVCSTARTUPTYPE=""Automatic""",
        "SQLSVCACCOUNT=""$SvcAccount""",
        "SQLSYSADMINACCOUNTS=""BUILTIN\Administrators""",
        "TCPENABLED=""1""",
        'SECURITYMODE="SQL"'
    )

    Set-Content -Path $TempConfigIni -Value $IniContents -Force
    Write-Output "[CONFIG-ENGINE] Volatile initialization manifest built safely at: $TempConfigIni"

    # 6. Microsoft SQL Server Setup Engine Execution Phase
    Write-Output "[SETUP-ENGINE] Spawning process workspace context threads. Launching setup.exe silently..."

    $Arguments = @("/ConfigurationFile=""$TempConfigIni""")
    $Arguments += "/SAPWD=""$SaPassword"""

    $ProcessParams = @{
        FilePath     = $SetupPath
        ArgumentList = $Arguments
        Wait         = $true
        NoNewWindow  = $true
        PassThru     = $true
    }

    $SetupProcess = Start-Process @ProcessParams
    $ExitCode = $SetupProcess.ExitCode

    Write-Output "[SETUP-ENGINE] Process thread execution completed. Capturing installation return signals..."

    # 7. Advanced Windows Installer 3010 Lifecycle State Management Evaluation
    if ($ExitCode -eq 0) {
        Write-Output "[SUCCESS] SQL Server setup engine transaction completed successfully (ExitCode: 0)."
    }
    elseif ($ExitCode -eq 3010) {
        Write-Output "=========================================================================================="
        Write-Output "[WARNING] SQL Server installation completed successfully but a Windows reboot is required."
        Write-Output "=========================================================================================="
        $ExitCode = 0
    }
    else {
        throw "[FATAL] SQL Server setup engine failed with critical transaction termination code: ($ExitCode). Review SQL Server Setup logs for additional details."
    }
}
finally {
    if (Test-Path -Path $TempConfigIni) {
        Write-Output "[CLEANUP] Purging dynamic configuration manifest artifacts safely from system cache..."
        Remove-Item -Path $TempConfigIni -Force
    }
}

Write-Output "====================================="
Write-Output "SQL SERVER INSTALLATION SUCCESSFUL"
Write-Output "====================================="

exit 0