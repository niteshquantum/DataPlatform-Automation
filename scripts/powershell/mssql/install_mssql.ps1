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

# === SQL AUTHENTICATION / SA LOGIN REPAIR ===
# Ensures the SQL Server instance is running in Mixed Mode (SQL + Windows
# Authentication) and that the 'sa' login is enabled with its password
# synced to mssql.conf's MSSQL_PASSWORD. This addresses a recurring issue
# where 'sa' ends up disabled or with a stale/out-of-sync password (e.g.
# after a manual server-side change, or a config file password rotation
# that was never applied to the running instance). Safe to re-run: if
# everything is already correct, it makes no changes.
function Repair-SqlAuthentication {
    param(
        [Parameter(Mandatory = $true)][string]$InstanceNameParam,
        [Parameter(Mandatory = $true)][string]$PortParam,
        [Parameter(Mandatory = $true)][string]$SaPasswordParam
    )

    Write-Output "[SQL-AUTH] Starting SQL authentication / 'sa' login repair for instance '$InstanceNameParam'..."

    # --- Resolve sqlcmd.exe. If it isn't available, this is a non-fatal
    #     diagnostic-only situation: we cannot verify/repair 'sa' without it,
    #     but installation itself already succeeded, so we warn and return
    #     rather than failing the whole pipeline. ---
    $SqlCmdTool = Get-Command "sqlcmd.exe" -ErrorAction SilentlyContinue
    if ($null -eq $SqlCmdTool) {
        Write-Output "[SQL-AUTH] WARNING: sqlcmd.exe not found on this host. Cannot verify/repair 'sa' login automatically. Skipping this step non-fatally."
        return
    }

    # --- Resolve the Windows Service name for this instance, same pattern
    #     used in start_mssql.ps1 / validate_install.ps1. ---
    $ExpectedServiceName = if ($InstanceNameParam -eq "MSSQLSERVER") { "MSSQLSERVER" } else { "MSSQL`$$InstanceNameParam" }

    # --- Resolve InstanceId from registry, needed to read/set LoginMode. ---
    $InstanceId = $null
    try {
        $InstanceId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" -ErrorAction Stop).$InstanceNameParam
    }
    catch {
        Write-Output "[SQL-AUTH] WARNING: Could not resolve InstanceId for '$InstanceNameParam' from registry. Skipping 'sa' repair non-fatally. Details: $($_.Exception.Message)"
        return
    }
    if ([string]::IsNullOrWhiteSpace($InstanceId)) {
        Write-Output "[SQL-AUTH] WARNING: InstanceId for '$InstanceNameParam' resolved empty. Skipping 'sa' repair non-fatally."
        return
    }

    $MssqlServerRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer"

    # --- Step 1: Ensure Mixed Mode authentication (LoginMode = 2). Value 1
    #     is Windows Authentication only, under which 'sa' cannot log in at
    #     all regardless of its enabled/disabled state or password. ---
    $CurrentLoginMode = $null
    try {
        $CurrentLoginMode = (Get-ItemProperty -Path $MssqlServerRegPath -Name "LoginMode" -ErrorAction Stop).LoginMode
    }
    catch {
        Write-Output "[SQL-AUTH] WARNING: Could not read LoginMode from registry at $MssqlServerRegPath. Skipping 'sa' repair non-fatally. Details: $($_.Exception.Message)"
        return
    }

    $LoginModeChanged = $false
    if ($CurrentLoginMode -ne 2) {
        Write-Output "[SQL-AUTH] LoginMode is currently '$CurrentLoginMode' (Windows Authentication only). Setting to Mixed Mode (2) so 'sa' can authenticate..."
        try {
            Set-ItemProperty -Path $MssqlServerRegPath -Name "LoginMode" -Value 2 -ErrorAction Stop
            $LoginModeChanged = $true
            Write-Output "[SQL-AUTH] LoginMode set to 2 (Mixed Mode)."
        }
        catch {
            Write-Output "[SQL-AUTH] WARNING: Failed to set LoginMode to Mixed Mode. Skipping 'sa' repair non-fatally. Details: $($_.Exception.Message)"
            return
        }
    }
    else {
        Write-Output "[SQL-AUTH] LoginMode already set to 2 (Mixed Mode). No change needed."
    }

    # --- LoginMode changes only take effect after a SQL Server service
    #     restart. Only restart if we actually changed it - never restart
    #     an already-correctly-configured, running instance unnecessarily. ---
    if ($LoginModeChanged) {
        Write-Output "[SQL-AUTH] Restarting service '$ExpectedServiceName' to apply the LoginMode change..."
        try {
            Restart-Service -Name $ExpectedServiceName -Force -ErrorAction Stop

            $RestartMaxWaitSeconds = 60
            $RestartPollIntervalSeconds = 3
            $RestartMaxIterations = $RestartMaxWaitSeconds / $RestartPollIntervalSeconds
            $RestartIteration = 0
            $RestartServiceRunning = $false

            while (-not $RestartServiceRunning -and $RestartIteration -lt $RestartMaxIterations) {
                $RestartIteration++
                Start-Sleep -Seconds $RestartPollIntervalSeconds
                $RestartSvcCheck = Get-Service -Name $ExpectedServiceName -ErrorAction SilentlyContinue
                if ($RestartSvcCheck -and $RestartSvcCheck.Status -eq 'Running') {
                    $RestartServiceRunning = $true
                }
            }

            if (-not $RestartServiceRunning) {
                Write-Output "[SQL-AUTH] WARNING: Service '$ExpectedServiceName' did not report Running within $RestartMaxWaitSeconds seconds after restart. Skipping 'sa' repair non-fatally."
                return
            }
            Write-Output "[SQL-AUTH] Service '$ExpectedServiceName' restarted and confirmed Running."
        }
        catch {
            Write-Output "[SQL-AUTH] WARNING: Failed to restart service '$ExpectedServiceName' after LoginMode change. Skipping 'sa' repair non-fatally. Details: $($_.Exception.Message)"
            return
        }
    }

    # --- Step 2: Connect via Windows (Trusted) Authentication - this script
    #     runs as NT AUTHORITY\SYSTEM, the same account that ran setup.exe,
    #     which SQL Server setup automatically grants sysadmin to. Then
    #     enable 'sa' and set its password to match mssql.conf. ---
    $SqlServerTarget = "localhost,$PortParam"

    # Escape single quotes in the password for safe inline T-SQL.
    $EscapedSaPassword = $SaPasswordParam -replace "'", "''"

    $SqlAuthQuery = "ALTER LOGIN [sa] WITH PASSWORD = '$EscapedSaPassword'; ALTER LOGIN [sa] ENABLE;"

    $SqlAuthMaxRetries = 10
    $SqlAuthRetryIntervalSeconds = 3
    $SqlAuthAttempt = 0
    $SqlAuthSucceeded = $false
    $SqlAuthLastOutput = $null
    $SqlAuthLastExitCode = $null

    while (-not $SqlAuthSucceeded -and $SqlAuthAttempt -lt $SqlAuthMaxRetries) {
        $SqlAuthAttempt++
        try {
            $SqlAuthLastOutput = & $SqlCmdTool.Source -S $SqlServerTarget -E -Q $SqlAuthQuery -b 2>&1
            $SqlAuthLastExitCode = $LASTEXITCODE
        }
        catch {
            $SqlAuthLastOutput = $_.Exception.Message
            $SqlAuthLastExitCode = 1
        }

        if ($SqlAuthLastExitCode -eq 0) {
            $SqlAuthSucceeded = $true
        }
        else {
            Write-Output "[SQL-AUTH] Attempt $SqlAuthAttempt/$SqlAuthMaxRetries : sqlcmd did not yet succeed (ExitCode: $SqlAuthLastExitCode). Retrying in $SqlAuthRetryIntervalSeconds seconds..."
            Start-Sleep -Seconds $SqlAuthRetryIntervalSeconds
        }
    }

    if (-not $SqlAuthSucceeded) {
        Write-Output "[SQL-AUTH] WARNING: Failed to enable/set 'sa' login password after $SqlAuthMaxRetries attempts. Last sqlcmd output: $SqlAuthLastOutput"
        return
    }
    Write-Output "[SQL-AUTH] 'sa' login password set and login enabled successfully."

    # --- Step 3: Verify 'sa' is actually enabled, as a final confirmation. ---
    try {
        $VerifyQuery = "SET NOCOUNT ON; SELECT is_disabled FROM sys.sql_logins WHERE name = 'sa';"
        $VerifyOutput = & $SqlCmdTool.Source -S $SqlServerTarget -E -Q $VerifyQuery -h -1 -W 2>&1
        $VerifyExitCode = $LASTEXITCODE
        if ($VerifyExitCode -eq 0) {
            $VerifyTrimmed = ($VerifyOutput | Out-String).Trim()
            if ($VerifyTrimmed -eq "0") {
                Write-Output "[SQL-AUTH] Verification confirmed: 'sa' login is enabled (is_disabled = 0)."
            }
            else {
                Write-Output "[SQL-AUTH] WARNING: Verification query returned unexpected is_disabled value: '$VerifyTrimmed'. 'sa' may still be disabled."
            }
        }
        else {
            Write-Output "[SQL-AUTH] WARNING: Verification query failed (ExitCode: $VerifyExitCode). Could not confirm 'sa' status. Output: $VerifyOutput"
        }
    }
    catch {
        Write-Output "[SQL-AUTH] WARNING: Verification query threw an exception non-fatally. Details: $($_.Exception.Message)"
    }

    Write-Output "[SQL-AUTH] SQL authentication / 'sa' login repair complete."
}
# === END SQL AUTHENTICATION / SA LOGIN REPAIR ===

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

    # Even on an idempotent skip, keep 'sa' authentication in sync with the
    # current mssql.conf - this is exactly the case that motivated this
    # function: an already-installed instance whose 'sa' login had drifted
    # (disabled, or password out of sync) was never touched again by a
    # re-run of this script until now.
    Repair-SqlAuthentication -InstanceNameParam $InstanceName -PortParam $InstancePort -SaPasswordParam $SaPassword

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

        # SECURITYMODE="SQL" in the .ini above already requests Mixed Mode at
        # install time, and /SAPWD already sets the initial 'sa' password.
        # This call is a defense-in-depth confirmation pass - it re-asserts
        # Mixed Mode and re-syncs 'sa' to mssql.conf, catching any case where
        # setup silently didn't honor SECURITYMODE (e.g. certain upgrade or
        # edition-specific paths).
        Repair-SqlAuthentication -InstanceNameParam $InstanceName -PortParam $InstancePort -SaPasswordParam $SaPassword
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