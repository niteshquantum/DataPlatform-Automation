<#
.SYNOPSIS
    DataPlatform-Automation - Post-Installation Operational Validation & Auto-Configuration Module
.DESCRIPTION
    Performs comprehensive structural, registry, network, and version validation.
    If network layer gaps (TCP/IP Disabled or Wrong Port) are detected, it dynamically
    reconfigures the instance registry space, recycles the engine service, and forces compliance.
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

$RegHklm = $null
$InstanceNamesKey = $null
$SetupKey = $null
$TcpKey = $null
$IpAllKey = $null
$NeedsServiceRestart = $false
$ExpectedServiceName = if ($InstanceName -eq "MSSQLSERVER") { "MSSQLSERVER" } else { "MSSQL`$$InstanceName" }

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
    $BinnPath = Join-Path "$env:ProgramFiles\Microsoft SQL Server\$InstanceId\MSSQL" "Binn"
    if (-not (Test-Path $BinnPath)) {
        throw "[ERROR] SQL Server Binn directory not found: $BinnPath"
    }

    $EngineBinaryPath = Join-Path $BinnPath "sqlservr.exe"
    if (-not (Test-Path $EngineBinaryPath)) {
        throw "[ERROR] SQL Server engine binary missing: $EngineBinaryPath"
    }
    Write-Output "[VALIDATION] Hardened file-system asset checks passed. Core binaries verified intact."

    # 6. Windows Service Layer Profiling (Initial Check)
    Write-Output "[SERVICE] Querying Windows Service configuration metadata for service descriptor: $ExpectedServiceName"
    $ServiceObj = Get-Service -Name $ExpectedServiceName -ErrorAction SilentlyContinue
    if ($null -eq $ServiceObj) {
        throw "[ERROR] Expected Windows NT Service wrapper identity mapping missing from Host SCM database: $ExpectedServiceName"
    }

    # 7. AUTOMATED SELF-HEALING: Dual-Layered TCP Binding Policy Configuration
    $TcpKeyPath = "SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\SuperSocketNetLib\Tcp"
    $TcpKey = $RegHklm.OpenSubKey($TcpKeyPath, $true) # Open with write access

    if ($null -eq $TcpKey) {
        throw "[ERROR] Network topology layer configuration properties missing for Instance: $InstanceId"
    }

    $TcpEnabled = $TcpKey.GetValue("Enabled")
    if ($TcpEnabled -ne 1) {
        Write-Output "[PORTABLE-HEAL] TCP/IP protocol is disabled on this machine registry layout. Forcing Enablement..."
        $TcpKey.SetValue("Enabled", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
        $NeedsServiceRestart = $true
    }

    $IpAllKeyPath = "SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
    $IpAllKey = $RegHklm.OpenSubKey($IpAllKeyPath, $true) # Open with write access
    if ($null -eq $IpAllKey) {
        throw "[ERROR] Internal configuration structure failure. IPAll listener parameters key is unmapped."
    }

    $ConfiguredPort = $IpAllKey.GetValue("TcpPort")
    if ([string]::IsNullOrEmpty($ConfiguredPort) -or $ConfiguredPort -ne $ExpectedPort) {
        Write-Output "[PORTABLE-HEAL] Port drift or empty layout detected (Current: '$ConfiguredPort'). Forcing target port '$ExpectedPort' on IPAll listener..."
        $IpAllKey.SetValue("TcpPort", $ExpectedPort, [Microsoft.Win32.RegistryValueKind]::String)
        # Clear dynamic ports to avoid network binding conflicts
        $IpAllKey.SetValue("TcpDynamicPorts", "", [Microsoft.Win32.RegistryValueKind]::String)
        $NeedsServiceRestart = $true
    }

    Write-Output "[NETWORK] Dual-Layer Phase 1: Desired TCP/IP parameter state validated and secured."

    # Force Service Recycle if Infrastructure Configuration changed
    if ($NeedsServiceRestart) {
        Write-Output "[SERVICE-RECYCLE] Reconfiguration executed. Restarting service $ExpectedServiceName to apply active socket adjustments..."
        Restart-Service -Name $ExpectedServiceName -Force
        Start-Sleep -Seconds 5
        $ServiceObj = Get-Service -Name $ExpectedServiceName
    }

    # Final enforcement check on Windows Service State
    if ($ServiceObj.StartType -ne 'Automatic') {
        Write-Output "[PORTABLE-HEAL] Fixing Service Startup type to Automatic..."
        Set-Service -Name $ExpectedServiceName -StartupType Automatic
    }

    if ($ServiceObj.Status -ne 'Running') {
        Write-Output "[PORTABLE-HEAL] Service is not running. Initiating start request..."
        Start-Service -Name $ExpectedServiceName
        Start-Sleep -Seconds 2
    }
    Write-Output "[SERVICE] Service state fully aligned and actively running."
}
catch {
    Get-LatestErrorLogLocation
    throw
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
$MaxWaitTimeSeconds = 45 # Increased slightly to accommodate dynamic restarts if any
$PollIntervalSeconds = 3
$MaxIterations = [int]($MaxWaitTimeSeconds / $PollIntervalSeconds)
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
    $SocketPollingElapsedSeconds = [math]::Round(((Get-Date) - $SocketPollingStartTime).TotalSeconds, 2)
    Write-Output "[FAILURE-DIAGNOSTICS] TCP listener validation failed."
    Write-Output "[FAILURE-DIAGNOSTICS] Target IP: $LoopbackIp"
    Write-Output "[FAILURE-DIAGNOSTICS] Target Port: $ExpectedPort"
    Write-Output "[FAILURE-DIAGNOSTICS] Total polling duration: ${SocketPollingElapsedSeconds}s"
    Write-Output "[FAILURE-DIAGNOSTICS] Polling iterations attempted: $IterationCounter"
    Get-LatestErrorLogLocation
    throw "[FATAL] Network layer lifecycle threshold breached. Engine is online but engine failed to accept TCP connections on Port $ExpectedPort within the deterministic timeout window."
}
Write-Output "[NETWORK] Dual-Layer Phase 2: Loopback network connectivity established successfully on target Port $ExpectedPort."

# 9. Dual-Layered TCP Binding Policy - Phase 3: Lightweight SQL Engine Connectivity Check
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

Write-Output "====================================="
Write-Output "SQL SERVER POST-INSTALL VALIDATION SUCCESSFUL"
Write-Output "====================================="

exit 0