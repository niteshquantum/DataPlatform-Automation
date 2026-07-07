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

# === ODBC DRIVER ORPHAN RECOVERY (Windows Installer Error 1706) ===
# SQL Server's setup.exe bundles the Microsoft ODBC Driver as a prerequisite.
# If a PRIOR install attempt (on this machine, at any point in its history)
# left behind a Windows Installer product registration for that ODBC driver
# whose cached source package (C:\Windows\Installer\<guid>.msi) has since
# been deleted (disk cleanup, AV quarantine, manual cleanup, etc.), Windows
# Installer will try to reuse that now-missing cached package during setup
# and fail with error 1706: "An installation package ... cannot be found."
#
# This function dynamically discovers any such orphaned ODBC Driver
# registration (no hardcoded ProductCodes - those differ per machine/version)
# and, only when the cached source is genuinely missing, removes the stale
# registration so SQL Server's own bundled ODBC installer can proceed
# cleanly. Healthy, valid installations are left completely untouched.
function Convert-CompressedGuidToStandard {
    param([Parameter(Mandatory = $true)][string]$Compressed)

    if ($Compressed.Length -ne 32) { return $null }

    function Reverse-BytePairs {
        param([string]$HexString)
        $bytePairs = for ($i = 0; $i -lt $HexString.Length; $i += 2) { $HexString.Substring($i, 2) }
        $reversed = $bytePairs[($bytePairs.Length - 1)..0]
        return ($reversed -join '')
    }

    $g1 = Reverse-BytePairs $Compressed.Substring(0, 8)
    $g2 = Reverse-BytePairs $Compressed.Substring(8, 4)
    $g3 = Reverse-BytePairs $Compressed.Substring(12, 4)
    $g4 = Reverse-BytePairs $Compressed.Substring(16, 4)
    $g5 = Reverse-BytePairs $Compressed.Substring(20, 12)

    return "{$g1-$g2-$g3-$g4-$g5}"
}

function Repair-OrphanedOdbcDriver {
    Write-Output "[ODBC-RECOVERY] Scanning for orphaned Microsoft ODBC Driver registrations (Windows Installer error 1706 prevention)..."

    # S-1-5-18 = LocalSystem. This script always runs elevated as SYSTEM
    # (via the elevation auto-dispatch above), so this is the correct,
    # machine-wide view of installed products.
    $UserDataRoot = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"

    if (-not (Test-Path -Path $UserDataRoot)) {
        Write-Output "[ODBC-RECOVERY] Windows Installer UserData root not found; nothing to scan."
        return
    }

    $ProductKeys = Get-ChildItem -Path $UserDataRoot -ErrorAction SilentlyContinue
    if ($null -eq $ProductKeys -or $ProductKeys.Count -eq 0) {
        Write-Output "[ODBC-RECOVERY] No installed products found under Windows Installer UserData; nothing to scan."
        return
    }

    $OrphanCount = 0

    foreach ($ProductKey in $ProductKeys) {
        $InstallPropsPath = Join-Path -Path $ProductKey.PSPath -ChildPath "InstallProperties"
        if (-not (Test-Path -Path $InstallPropsPath)) { continue }

        $Props = Get-ItemProperty -Path $InstallPropsPath -ErrorAction SilentlyContinue
        if ($null -eq $Props) { continue }

        $DisplayName = $Props.DisplayName
        if ([string]::IsNullOrEmpty($DisplayName)) { continue }

        # Dynamic match - covers "ODBC Driver 17 for SQL Server",
        # "ODBC Driver 18 for SQL Server", future versions, etc.
        if ($DisplayName -notmatch '(?i)ODBC Driver.*SQL Server') { continue }

        Write-Output "[ODBC-RECOVERY] Found registered component: '$DisplayName'"

        $CompressedCode = $ProductKey.PSChildName
        $ProductCode = Convert-CompressedGuidToStandard -Compressed $CompressedCode

        if ($null -eq $ProductCode) {
            Write-Output "[ODBC-RECOVERY] Could not parse a valid ProductCode from registry key '$CompressedCode'; skipping this entry."
            continue
        }

        Write-Output "[ODBC-RECOVERY] Resolved ProductCode: $ProductCode"

        $LocalPackage = $Props.LocalPackage
        $CacheValid = (-not [string]::IsNullOrEmpty($LocalPackage)) -and (Test-Path -Path $LocalPackage)

        if ($CacheValid) {
            Write-Output "[ODBC-RECOVERY] Cached installer package is present and valid ($LocalPackage). This installation is healthy - leaving it untouched."
            continue
        }

        $OrphanCount++
        Write-Output "[ODBC-RECOVERY] Cached installer package is MISSING (expected at: '$LocalPackage'). This is the exact condition that produces Windows Installer error 1706."
        Write-Output "[ODBC-RECOVERY] Attempting silent removal via msiexec first..."

        $UninstallArgs = "/X $ProductCode /qn REBOOT=ReallySuppress"
        $UninstallProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $UninstallArgs -Wait -PassThru -NoNewWindow
        $UninstallExit = $UninstallProcess.ExitCode

        if ($UninstallExit -eq 0 -or $UninstallExit -eq 3010) {
            Write-Output "[ODBC-RECOVERY] Broken component removed successfully via msiexec (ExitCode: $UninstallExit)."
            continue
        }

        Write-Output "[ODBC-RECOVERY] msiexec uninstall also failed (ExitCode: $UninstallExit) - expected here, since the cached package msiexec itself needs is missing."
        Write-Output "[ODBC-RECOVERY] Falling back to direct Windows Installer registration cleanup (equivalent to Microsoft's install/uninstall troubleshooting remediation for this scenario)..."

        try {
            Remove-Item -Path $ProductKey.PSPath -Recurse -Force -ErrorAction Stop
            Write-Output "[ODBC-RECOVERY] Removed orphaned UserData product registration for $ProductCode."

            $InstallerProductsPath = "HKLM:\SOFTWARE\Classes\Installer\Products\$CompressedCode"
            if (Test-Path -Path $InstallerProductsPath) {
                Remove-Item -Path $InstallerProductsPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output "[ODBC-RECOVERY] Removed orphaned Installer\Products advertisement entry."
            }

            $UninstallKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"
            if (Test-Path -Path $UninstallKeyPath) {
                Remove-Item -Path $UninstallKeyPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output "[ODBC-RECOVERY] Removed orphaned Add/Remove Programs entry."
            }

            Write-Output "[ODBC-RECOVERY] Orphaned registration for '$DisplayName' ($ProductCode) fully cleared. SQL Server setup can now install the ODBC driver fresh from its own bundled media without hitting error 1706."
        }
        catch {
            Write-Output "[ODBC-RECOVERY] WARNING: Could not fully clear orphaned registration for '$DisplayName' ($ProductCode). Details: $($_.Exception.Message)"
            Write-Output "[ODBC-RECOVERY] Continuing with SQL Server installation anyway - if error 1706 recurs for this specific product, it will need targeted follow-up."
        }
    }

    if ($OrphanCount -eq 0) {
        Write-Output "[ODBC-RECOVERY] No orphaned ODBC Driver registrations found. Nothing to repair."
    }
    else {
        Write-Output "[ODBC-RECOVERY] Orphan scan complete. $OrphanCount orphaned registration(s) processed."
    }
}
# === END ODBC DRIVER ORPHAN RECOVERY ===

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

# 4.5. Preemptive ODBC Driver orphan recovery, before SQL Server setup runs.
Repair-OrphanedOdbcDriver

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