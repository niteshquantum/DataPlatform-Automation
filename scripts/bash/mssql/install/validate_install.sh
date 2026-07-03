<#
.SYNOPSIS
    DataPlatform-Automation - Post-Installation Operational Validation Module
.DESCRIPTION
    Performs comprehensive, read-only structural, registry, network, and version 
    validation of the deployed SQL Server instance. Zero side-effects architecture.
.NOTES
    Target OS: Windows Server 2019 / 2022
    PowerShell Version: 5.1+
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Define strict relative paths based on repository freeze structure
$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$ConfigPath = Join-Path $PROJECT_ROOT "config\windows\mssql.conf"

Write-Output "[INIT] Starting SQL Server production post-flight validation pipeline..."

# 1. Pre-Flight Administrator Context Security Validation
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    throw "[ERROR] Elevated Administrator permissions are strictly required to execute instance validation."
}
Write-Output "[SECURITY] Verified execution context runs with elevated administrative privileges."

# 2. Read and Parse Configuration File
if (-not (Test-Path -Path $ConfigPath)) {
    throw "[ERROR] Configuration file not found at expected path: $ConfigPath"
}

Write-Output "[CONFIG] Loading configurations from $ConfigPath"
$Config = @{}
Get-Content -Path $ConfigPath | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $Key, $Value = $_ -split '=', 2
    $Config[$Key.Trim()] = $Value.Trim()
}

# Scalable Required Configuration Keys Validation
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

# Initialize scope variables for safety block cleanup leaks
$RegHklm = $null
$InstanceNamesKey = $null
$SetupKey = $null
$TcpKey = $null
$IpAllKey = $null

try {
    # 3. Native 64-Bit Registry View Enforcement
    Write-Output "[REGISTRY] Binding to native 64-bit local machine registry view..."
    $RegHklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)

    # 4. Microsoft Documented Registry Topology Verification & Instance Mapping
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

    # 5. SQL Server Version Cross-Check Validation
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

    
# 6. Hardened Binary Layer Verification

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

    # 7. Windows Service Layer Profiling
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

    # 8. Dual-Layered TCP Binding Policy - Phase 1: Registry Desired State Check
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
finally {
    # Guard explicit closure allocation boundaries to prevent active session handle leakage leaks
    if ($null -ne $IpAllKey) { $IpAllKey.Close() }
    if ($null -ne $TcpKey) { $TcpKey.Close() }
    if ($null -ne $SetupKey) { $SetupKey.Close() }
    if ($null -ne $InstanceNamesKey) { $InstanceNamesKey.Close() }
    if ($null -ne $RegHklm) { $RegHklm.Close() }
    Write-Output "[REGISTRY] Safely released and deallocated all local machine registry handles."
}

# 9. Dual-Layered TCP Binding Policy - Phase 2: Deterministic Live Socket Polling Loop
Write-Output "[NETWORK] Dual-Layer Phase 2: Initializing active live socket connection validation testing block..."
$LoopbackIp = "127.0.0.1"
$MaxWaitTimeSeconds = 30
$PollIntervalSeconds = 2
$MaxIterations = $MaxWaitTimeSeconds / $PollIntervalSeconds
$IterationCounter = 0
$SocketConnected = $false

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
        # Guarantee network resource disposal in a hardened environment lifecycle wrapper block
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
    throw "[FATAL] Network layer lifecycle threshold breached. Engine is online but engine failed to accept TCP connections on Port $ExpectedPort within the deterministic timeout window."
}
Write-Output "[NETWORK] Dual-Layer Phase 2: Loopback network connectivity established successfully on target Port $ExpectedPort."

Write-Output "====================================="
Write-Output "SQL SERVER POST-INSTALL VALIDATION SUCCESSFUL"
Write-Output "====================================="

exit 0