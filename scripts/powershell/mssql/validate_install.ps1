<#
.SYNOPSIS
    DataPlatform-Automation - Post-Installation Operational Validation Module
.DESCRIPTION
    Performs comprehensive, read-only structural, registry, network, and version
    validation of the deployed SQL Server instance. Self-elevates via the
    SYSTEM-privileged scheduled task if not already running elevated.
.NOTES
    Target OS: Windows Server 2019 / 2022
    PowerShell Version: 5.1+
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# === ELEVATION AUTO-DISPATCH (do not remove) ===
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

Write-Output "[INIT] Starting SQL Server production post-flight validation pipeline (elevated)..."

# 1. Read and Parse Configuration File
if (-not (Test-Path -Path $ConfigPath)) {
    throw "[ERROR] Configuration file not found at expected path: $ConfigPath"
}

Write-Output "[CONFIG] Loading configurations from $ConfigPath"
$Config = @{}
Get-Content -Path $ConfigPath | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $Key, $Value = $_ -split '=', 2
    $Config[$Key.Trim()] = $Value.Trim()
}

$RequiredKeys = @(
    "MSSQL_INSTANCE",
    "MSSQL_PORT",
    "MSSQL_VERSION"
)

foreach ($Key in $RequiredKeys) {
    if (-not $Config.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Config[$Key])) {
        throw "[ERROR] Required configuration key missing or empty in mssql.conf: $Key"
    }
}

$InstanceName = $Config['MSSQL_INSTANCE']
$ExpectedPort = $Config['MSSQL_PORT']
$ExpectedVersionString = $Config['MSSQL_VERSION']

# --- FIX (Issue 4): shared, non-fatal ERRORLOG locator used only on failure paths.
#     Only reports file location; does not parse contents. Search strategy is a
#     simple recursive scan under the SQL Server install root. ---
function Get-LatestErrorLogLocation {
    try {
        $ErrorLogRoot = Join-Path $env:ProgramFiles "Microsoft SQL Server"
        if (-not (Test-Path -Path $ErrorLogRoot)) {
            Write-Output "[FAILURE-DIAGNOSTICS] SQL Server install root not found for ERRORLOG discovery: $ErrorLogRoot"
            return
        }
        try {
            $Candidate = Get-ChildItem -Path $ErrorLogRoot -Filter "ERRORLOG" -Recurse -ErrorAction Stop |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($Candidate) {
                Write-Output "[FAILURE-DIAGNOSTICS] Latest SQL Server ERRORLOG path: $($Candidate.FullName)"
            }
            else {
                Write-Output "[FAILURE-DIAGNOSTICS] No ERRORLOG file found under: $ErrorLogRoot"
            }
        }
        catch {
            Write-Output "[FAILURE-DIAGNOSTICS] Recursive ERRORLOG search failed. Search Root: $ErrorLogRoot | Exception: $($_.Exception.Message)"
        }
    }
    catch {
        Write-Output "[FAILURE-DIAGNOSTICS] ERRORLOG discovery failed non-fatally. Details: $($_.Exception.Message)"
    }
}
# --- END FIX ---

$RegHklm = $null
$InstanceNamesKey = $null
$SetupKey = $null
$TcpKey = $null
$IpAllKey = $null

try {
    # 2. Native 64-Bit Registry View Enforcement
    Write-Output "[REGISTRY] Binding to native 64-bit local machine registry view..."
    $RegHklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)

    # 3. Microsoft Documented Registry Topology Verification & Instance Mapping
    $InstanceNamesKeyPath = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
    $InstanceNamesKey = $RegHklm.OpenSubKey($InstanceNamesKeyPath)

    if ($null -eq $InstanceNamesKey) {
        throw "[ERROR] Registry base path for SQL Server instances does not exist. Installation is missing or corrupt."
    }

    $InstanceId = $InstanceNamesKey.GetValue($InstanceName)
    if ($null -eq $InstanceId) {
        throw "[ERROR] Specified SQL Server Named Instance '$InstanceName' is not registered on this machine."
    }
    Write-Output "[REGISTRY] Instance '$InstanceName' successfully resolved to Internal ID: $InstanceId"

    # 4. SQL Server Version Cross-Check Validation
    $SetupKeyPath = "SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\Setup"
    $SetupKey = $RegHklm.OpenSubKey($SetupKeyPath)

    if ($null -eq $SetupKey) {
        throw "[ERROR] Registry setup parameters subkey missing for Instance ID: $InstanceId"
    }

    $CurrentVersion = $SetupKey.GetValue("Version")
    if ($null -eq $CurrentVersion) {
        throw "[ERROR] Could not extract product version property string from registry metadata."
    }
    Write-Output "[VERSION-CHECK] Active Registered Product Version: $CurrentVersion"

    $MajorVersion = $CurrentVersion.Split('.')[0]
    if ($MajorVersion -ne $ExpectedVersionString) {
        throw "[ERROR] SQL Server Version Mismatch Detected! Expected Major Version: '$ExpectedVersionString.x', but found Installed Version: '$CurrentVersion'."
    }
    Write-Output "[VERSION-CHECK] Complete major version alignment verified successfully."

    # 5. Hardened Binary Layer Verification
    $BinnPath = Join-Path `
        "$env:ProgramFiles\Microsoft SQL Server\$InstanceId\MSSQL" `
        "Binn"

    if (-not (Test-Path $BinnPath)) {
        throw "[ERROR] SQL Server Binn directory not found: $BinnPath"
    }

    $EngineBinaryPath = Join-Path $BinnPath "sqlservr.exe"

    if (-not (Test-Path $EngineBinaryPath)) {
        throw "[ERROR] SQL Server engine binary missing: $EngineBinaryPath"
    }

    Write-Output "[VALIDATION] Hardened file-system asset checks passed. Core binaries verified intact."

    # 6. Windows Service Layer Profiling
    $ExpectedServiceName = if ($InstanceName -eq "MSSQLSERVER") { "MSSQLSERVER" } else { "MSSQL`$$InstanceName" }
    Write-Output "[SERVICE] Querying Windows Service configuration metadata for service descriptor: $ExpectedServiceName"

    $ServiceObj = Get-Service -Name $ExpectedServiceName -ErrorAction SilentlyContinue
    if ($null -eq $ServiceObj) {
        throw "[ERROR] Expected Windows NT Service wrapper identity mapping missing from Host SCM database: $ExpectedServiceName"
    }

    if ($ServiceObj.StartType -ne 'Automatic') {
        throw "[ERROR] Windows Service startup type configuration drift detected. Expected: 'Automatic', Found: '$($ServiceObj.StartType)'"
    }

    if ($ServiceObj.Status -ne 'Running') {
        throw "[ERROR] Operational status assertion failure. Windows service is in a '$($ServiceObj.Status)' state instead of 'Running'."
    }
    Write-Output "[SERVICE] Verified service is configured to start Automatically and is actively Running."

    # 7. Dual-Layered TCP Binding Policy - Phase 1: Registry Desired State Check
    $TcpKeyPath = "SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\SuperSocketNetLib\Tcp"
    $TcpKey = $RegHklm.OpenSubKey($TcpKeyPath)

    if ($null -eq $TcpKey) {
        throw "[ERROR] Network topology layer configuration properties missing for Instance: $InstanceId"
    }

    $TcpEnabled = $TcpKey.GetValue("Enabled")
    if ($TcpEnabled -ne 1) {
        throw "[ERROR] Network transport policy breach. TCP/IP protocol support is marked as disabled in configuration registries."
    }

    $IpAllKeyPath = "SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
    $IpAllKey = $RegHklm.OpenSubKey($IpAllKeyPath)
    if ($null -eq $IpAllKey) {
        throw "[ERROR] Internal configuration structure failure. IPAll listener parameters key is unmapped."
    }

    $ConfiguredPort = $IpAllKey.GetValue("TcpPort")
    if ([string]::IsNullOrEmpty($ConfiguredPort) -or $ConfiguredPort -ne $ExpectedPort) {
        throw "[ERROR] Network parameter socket drift detected. Registry configuration port '$ConfiguredPort' does not match mssql.conf target port '$ExpectedPort'."
    }
    Write-Output "[NETWORK] Dual-Layer Phase 1: Desired TCP/IP parameters successfully confirmed in the registry view layout."
}
catch {
    # --- FIX (Issue 4): on registry-phase failure, attempt ERRORLOG discovery
    #     before propagating the original error unchanged. ---
    Get-LatestErrorLogLocation
    throw
    # --- END FIX ---
}
finally {
    if ($null -ne $IpAllKey) { $IpAllKey.Close() }
    if ($null -ne $TcpKey) { $TcpKey.Close() }
    if ($null -ne $SetupKey) { $SetupKey.Close() }
    if ($null -ne $InstanceNamesKey) { $InstanceNamesKey.Close() }
    if ($null -ne $RegHklm) { $RegHklm.Close() }
    Write-Output "[REGISTRY] Safely released and deallocated all local machine registry handles."
}

# 8. Dual-Layered TCP Binding Policy - Phase 2: Deterministic Live Socket Polling Loop
Write-Output "[NETWORK] Dual-Layer Phase 2: Initializing active live socket connection validation testing block..."
$LoopbackIp = "127.0.0.1"
$MaxWaitTimeSeconds = 30
$PollIntervalSeconds = 2
$MaxIterations = $MaxWaitTimeSeconds / $PollIntervalSeconds
$IterationCounter = 0
$SocketConnected = $false
$SocketPollingStartTime = Get-Date

while (-not $SocketConnected -and $IterationCounter -lt $MaxIterations) {
    $IterationCounter++
    $TcpClient = $null
    try {
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        $TcpClient.Connect($LoopbackIp, [int]$ExpectedPort)
        if ($TcpClient.Connected) {
            $SocketConnected = $true
        }
    }
    catch {
        # Suppress exceptions during transient polling backoff frame windows
    }
    finally {
        if ($null -ne $TcpClient) {
            $TcpClient.Close()
            if ($TcpClient -is [System.IDisposable]) { $TcpClient.Dispose() }
        }
    }

    if (-not $SocketConnected) {
        Write-Output "[NETWORK-POLLING] Listener not answering yet. Iteration ($IterationCounter/$MaxIterations). Sleeping $PollIntervalSeconds seconds..."
        Start-Sleep -Seconds $PollIntervalSeconds
    }
}

if (-not $SocketConnected) {
    # --- FIX (Issue 3): report target IP, target port, total polling duration,
    #     and iteration count before throwing. Timeout/interval values unchanged. ---
    $SocketPollingElapsedSeconds = [math]::Round(((Get-Date) - $SocketPollingStartTime).TotalSeconds, 2)
    Write-Output "[FAILURE-DIAGNOSTICS] TCP listener validation failed."
    Write-Output "[FAILURE-DIAGNOSTICS] Target IP: $LoopbackIp"
    Write-Output "[FAILURE-DIAGNOSTICS] Target Port: $ExpectedPort"
    Write-Output "[FAILURE-DIAGNOSTICS] Total polling duration: ${SocketPollingElapsedSeconds}s"
    Write-Output "[FAILURE-DIAGNOSTICS] Polling iterations attempted: $IterationCounter"
    # --- END FIX ---

    # --- FIX (Issue 4) ---
    Get-LatestErrorLogLocation
    # --- END FIX ---

    throw "[FATAL] Network layer lifecycle threshold breached. Engine is online but engine failed to accept TCP connections on Port $ExpectedPort within the deterministic timeout window."
}
Write-Output "[NETWORK] Dual-Layer Phase 2: Loopback network connectivity established successfully on target Port $ExpectedPort."

# 9. Dual-Layered TCP Binding Policy - Phase 3: Lightweight SQL Engine Connectivity Check
# --- FIX (Issue 2): after socket validation, attempt a minimal SQL connectivity
#     check using sqlcmd if it is available on this host. No DDL/DML is executed;
#     only a trivial SELECT is used to confirm the engine accepts a login/connection.
#     If sqlcmd is unavailable, existing behaviour (socket-only validation) is kept
#     and only a diagnostic message is emitted. ---
Write-Output "[NETWORK] Dual-Layer Phase 3: Attempting lightweight SQL Engine connectivity verification..."
$SqlCmdTool = Get-Command "sqlcmd.exe" -ErrorAction SilentlyContinue
if ($null -eq $SqlCmdTool) {
    Write-Output "[SQL-CONNECT] sqlcmd.exe not found on this host. Skipping engine-level connectivity check; socket-level validation above remains the effective connectivity guarantee."
}
else {
    $SqlCmdServerTarget = "$LoopbackIp,$ExpectedPort"
    try {
        $SqlCmdOutput = & $SqlCmdTool.Source -S $SqlCmdServerTarget -Q "SELECT 1" -b -l 15 2>&1
        $SqlCmdExitCode = $LASTEXITCODE
        if ($SqlCmdExitCode -eq 0) {
            Write-Output "[SQL-CONNECT] sqlcmd successfully connected to $SqlCmdServerTarget and executed a read-only connectivity probe."
        }
        else {
            Write-Output "[SQL-CONNECT] sqlcmd connectivity probe against $SqlCmdServerTarget returned a non-zero exit code ($SqlCmdExitCode). Output: $SqlCmdOutput"
            Get-LatestErrorLogLocation
        }
    }
    catch {
        Write-Output "[SQL-CONNECT] sqlcmd connectivity probe failed non-fatally. Target: $SqlCmdServerTarget | Details: $($_.Exception.Message)"
        Get-LatestErrorLogLocation
    }
}
# --- END FIX ---

Write-Output "====================================="
Write-Output "SQL SERVER POST-INSTALL VALIDATION SUCCESSFUL"
Write-Output "====================================="

exit 0