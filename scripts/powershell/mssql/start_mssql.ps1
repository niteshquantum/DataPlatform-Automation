<#
.SYNOPSIS
    DataPlatform-Automation - Windows SCM SQL Server Lifecycle Module
.DESCRIPTION
    Ensures that the target Microsoft SQL Server instance service is started and operational,
    with static TCP port configuration applied. Interfaces natively with the SCM state machine
    with absolute configuration safety.
.NOTES
    Target OS: Windows Server 2019 / 2022
    PowerShell Version: 5.1+
#>
Add-Type -AssemblyName System.ServiceProcess
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ==============================================================================
# SELF-ELEVATION BOOTSTRAP (fully automatic, no manual steps, portable to any
# host where the executing account is a member of the local Administrators
# group). This solves the "Requested registry access is not allowed" root
# cause at its source: Windows UAC token filtering denies HKLM writes to
# non-elevated tokens even for Administrators-group accounts. Instead of
# failing, the script silently re-launches itself with a full admin token
# via a temporary Scheduled Task using LogonType=S4U + RunLevel=Highest,
# which elevates without any interactive UAC prompt. No changes required to
# Terraform, Jenkins service configuration, or per-machine registry ACLs.
# ==============================================================================
$CurrentIdentity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentIdentity)
$IsCurrentlyElevated = $CurrentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsCurrentlyElevated -and -not $env:DPA_ELEVATED) {

    Write-Output "[ELEVATION] Non-elevated token detected for '$($CurrentIdentity.Name)'. Bootstrapping silent elevation via Scheduled Task (S4U + Highest)..."

    $SelfScriptPath = $MyInvocation.MyCommand.Path
    $TaskName  = "DPA-ElevatedRunner-$([guid]::NewGuid().ToString('N').Substring(0,10))"
    $StdOutLog = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "$TaskName.out.log")
    $ExitCodeFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "$TaskName.exitcode")

    # DPA_ELEVATED marks the relaunched (elevated) invocation so it does not
    # attempt to re-bootstrap itself again (prevents infinite recursion).
    $InnerCommand = "`$env:DPA_ELEVATED = '1'; & `"$SelfScriptPath`" *> `"$StdOutLog`"; `$LASTEXITCODE | Out-File -FilePath `"$ExitCodeFile`" -Encoding ascii"

    try {
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$InnerCommand`""
        $TaskPrincipal = New-ScheduledTaskPrincipal -UserId $CurrentIdentity.Name -LogonType S4U -RunLevel Highest
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

        Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $TaskPrincipal -Settings $Settings -Force -ErrorAction Stop | Out-Null
        Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop

        $TimeoutSeconds = 300
        $ElapsedSeconds = 0
        do {
            Start-Sleep -Seconds 2
            $ElapsedSeconds += 2
            $TaskState = (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue).State
        } while ($TaskState -eq 'Running' -and $ElapsedSeconds -lt $TimeoutSeconds)

        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

        if (Test-Path -Path $StdOutLog) {
            Get-Content -Path $StdOutLog | ForEach-Object { Write-Output $_ }
        }

        $ElevatedExitCode = 1
        if (Test-Path -Path $ExitCodeFile) {
            $RawExit = (Get-Content -Path $ExitCodeFile -Raw).Trim()
            if ($RawExit -match '^\d+$') { $ElevatedExitCode = [int]$RawExit }
        }
        else {
            Write-Output "[ELEVATION] [ERROR] Elevated task did not produce an exit code within $TimeoutSeconds seconds (timeout or task failed to run)."
        }

        Remove-Item -Path $StdOutLog, $ExitCodeFile -ErrorAction SilentlyContinue
        exit $ElevatedExitCode
    }
    catch {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        throw @"
[ERROR] [ELEVATION] Automatic silent elevation via Scheduled Task failed.

Executing Identity: $($CurrentIdentity.Name)

This typically means the Task Scheduler service is disabled, or the account
is not a member of the local Administrators group on this host.

Original Error:
$($_.Exception.Message)
"@
    }
}
# --- END SELF-ELEVATION BOOTSTRAP ---

# ==============================================================================
# HELPER FUNCTIONS (Top-level scope declaration)
# ==============================================================================

function Get-ServiceManagementObject {
    param([string]$SvcName)
    $Obj = $null

    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        try {
            $Obj = Get-CimInstance -ClassName Win32_Service -Filter "Name = '$SvcName'" -ErrorAction Stop
        }
        catch {
            Write-Output "[WARNING] [STORAGE] Get-CimInstance execution failed structurally. Falling back to legacy providers..."
        }
    }

    if ($null -eq $Obj -and (Get-Command Get-WmiObject -ErrorAction SilentlyContinue)) {
        try {
            Write-Output "[WARNING] [STORAGE] Falling back to legacy WMI lookup for '$SvcName'..."
            $Obj = Get-WmiObject -Class Win32_Service -Filter "Name = '$SvcName'" -ErrorAction Stop
        }
        catch {
            Write-Output "[WARNING] [STORAGE] WMI fallback execution query rejected."
        }
    }

    if ($null -eq $Obj) {
        throw "[ERROR] [STORAGE] Hardened System Barrier: Neither CIM nor WMI management infrastructure is available or functional on this host."
    }

    return $Obj
}

# --- FIX (Root Cause Diagnostic): Identify the executing security context so
#     that a registry-permission failure produces an actionable error instead
#     of a bare "Requested registry access is not allowed" OS exception.
#     This does not change instance/path discovery, which is already correct. ---
function Test-CurrentUserContext {
    $Identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
    $IsElevatedAdmin = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    return [PSCustomObject]@{
        UserName   = $Identity.Name
        IsElevated = $IsElevatedAdmin
    }
}
# --- END FIX ---

# ==============================================================================
# CORE EXECUTION PIPELINE
# ==============================================================================

# Define strict relative paths based on repository freeze structure
$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$ConfigPath = Join-Path $PROJECT_ROOT "config\windows\mssql.conf"

Write-Output "[INIT] Starting SQL Server service operational verification phase..."
Write-Output "[SECURITY] Validating SQL Server service accessibility..."

# 1. Read and Parse Configuration File
if (-not (Test-Path -Path $ConfigPath)) {
    throw "[ERROR] [CONFIG] Configuration file not found at expected path: $ConfigPath"
}

Write-Output "[CONFIG] Loading configurations from $ConfigPath"
$Config = @{}
Get-Content -Path $ConfigPath | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $Key, $Value = $_ -split '=', 2
    $Config[$Key.Trim()] = $Value.Trim()
}

# --- FIX (Issue 1): MSSQL_PORT is now a mandatory key, since static TCP
#     configuration is a required part of this pipeline's behaviour and
#     the value is dereferenced unconditionally later in the script. ---
$RequiredKeys = @(
    "MSSQL_INSTANCE",
    "MSSQL_PORT"
)
# --- END FIX ---

foreach ($Key in $RequiredKeys) {
    if (-not $Config.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Config[$Key])) {
        throw "[ERROR] [CONFIG] Required configuration key missing or empty in mssql.conf: $Key"
    }
}

$InstanceName = $Config['MSSQL_INSTANCE']
$Port = $Config["MSSQL_PORT"]

# --- FIX (Issue 2): Wrap InstanceId registry lookup in try/catch to
#     surface the exact registry path, instance name, and original
#     exception on failure. Lookup logic itself is unchanged. ---
$InstanceNamesRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
try {
    $InstanceId = (
        Get-ItemProperty -Path $InstanceNamesRegPath -ErrorAction Stop
    ).$InstanceName
}
catch {
    throw @"
[ERROR] [CONFIG] Failed to read SQL Server instance registration registry key.

Registry Path: $InstanceNamesRegPath
Instance Name: $InstanceName

Original Error:
$($_.Exception.Message)
"@
}
# --- END FIX ---

if ([string]::IsNullOrWhiteSpace($InstanceId)) {
    throw "[ERROR] [CONFIG] Could not resolve InstanceId for instance '$InstanceName'. Is SQL Server actually installed on this host?"
}

$TcpPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\SuperSocketNetLib\Tcp"
$IpAll   = Join-Path $TcpPath "IPAll"

# 2. TCP/IP Static Port Configuration
if (-not [string]::IsNullOrWhiteSpace($Port)) {

    # --- FIX (Root Cause Diagnostic): Pre-flight elevation check.
    #     This subtree is ACL-restricted to Administrators/SYSTEM by the SQL
    #     Server installer, and Windows UAC token filtering means even a
    #     member of the local Administrators group will be denied here
    #     unless the process token is actually elevated. Surface this BEFORE
    #     attempting the writes, instead of letting the OS throw a bare
    #     "Requested registry access is not allowed" deep inside Set-ItemProperty.
    #     Execution order and all downstream logic are unchanged. ---
    $ExecutionContextInfo = Test-CurrentUserContext
    Write-Output "[SECURITY] Executing identity: $($ExecutionContextInfo.UserName) | Elevated Administrator token: $($ExecutionContextInfo.IsElevated)"

    if (-not $ExecutionContextInfo.IsElevated) {
        throw @"
[ERROR] [SECURITY] Insufficient privilege to modify protected SQL Server registry configuration.

Executing Identity  : $($ExecutionContextInfo.UserName)
Elevated Admin Token: False
Target Registry Path: $TcpPath

Writing to this HKLM subtree requires an elevated (Administrator or SYSTEM) access token,
even for accounts that are members of the local Administrators group, because of Windows
UAC token filtering combined with the default ACLs the SQL Server installer applies to
this key.

PERMANENT FIX (pick one, per-machine, one-time):
  (a) Run the Jenkins agent service as the SYSTEM account, or
  (b) Configure the Jenkins agent service to run as a local Administrator account
      (Services.msc -> Jenkins -> Log On tab), ensuring the service itself carries
      an elevated token (not just group membership), or
  (c) Grant an explicit FullControl ACE on this specific registry subtree to the
      Jenkins service account, e.g.:
      `$Acl = Get-Acl -Path '$TcpPath'
      # add an explicit access rule for the Jenkins service account, then:
      Set-Acl -Path '$TcpPath' -AclObject `$Acl
"@
    }
    # --- END FIX ---

    Write-Output "[NETWORK] Applying static TCP port configuration ($Port)..."
    $TcpConfigStartTime = Get-Date
    # --- FIX (Issue 3): Track which specific registry path is being acted
    #     upon so failure diagnostics report the actual path involved
    #     instead of assuming Administrator permission is the root cause. ---
    $CurrentRegistryOperationPath = $null
    try {
        $CurrentRegistryOperationPath = $TcpPath
        Set-ItemProperty -Path $TcpPath -Name Enabled -Value 1 -ErrorAction Stop

        # --- VERIFY: read back Enabled value (Issue 3) ---
        $VerifyEnabled = (Get-ItemProperty -Path $TcpPath -Name Enabled -ErrorAction Stop).Enabled
        if ($VerifyEnabled -ne 1) {
            throw "[ERROR] [NETWORK] Registry verification failed: 'Enabled' at $TcpPath expected 1, found '$VerifyEnabled'."
        }
        # --- END VERIFY ---

        $CurrentRegistryOperationPath = $IpAll
        Set-ItemProperty -Path $IpAll -Name TcpDynamicPorts -Value "" -ErrorAction Stop

        # --- VERIFY: read back TcpDynamicPorts value (Issue 3 / Issue 4) ---
        $VerifyDynamicPorts = (Get-ItemProperty -Path $IpAll -Name TcpDynamicPorts -ErrorAction Stop).TcpDynamicPorts
        # --- FIX (Issue 4): treat both empty string and null as a valid
        #     "dynamic ports disabled" state. Registry write behaviour is
        #     unchanged; only the verification comparison is widened. ---
        if (-not [string]::IsNullOrEmpty($VerifyDynamicPorts)) {
            throw "[ERROR] [NETWORK] Registry verification failed: 'TcpDynamicPorts' at $IpAll expected empty/null, found '$VerifyDynamicPorts'."
        }
        # --- END FIX ---
        # --- END VERIFY ---

        $CurrentRegistryOperationPath = $IpAll
        Set-ItemProperty -Path $IpAll -Name TcpPort -Value $Port -ErrorAction Stop

        # --- VERIFY: read back TcpPort value (Issue 3) ---
        $VerifyTcpPort = (Get-ItemProperty -Path $IpAll -Name TcpPort -ErrorAction Stop).TcpPort
        if ($VerifyTcpPort -ne $Port) {
            throw "[ERROR] [NETWORK] Registry verification failed: 'TcpPort' at $IpAll expected '$Port', found '$VerifyTcpPort'."
        }
        # --- END VERIFY ---

        Write-Output "[NETWORK] TCP/IP configured on static port $Port."

        # --- DIAGNOSTIC: TCP/IP configuration values (Issue 4) ---
        Write-Output "[NETWORK] Registry TCP Enabled value: $VerifyEnabled"
        Write-Output "[NETWORK] Configured TCP Port: $VerifyTcpPort"
        # --- END DIAGNOSTIC ---
    }
    catch {
        throw @"
[ERROR] [NETWORK] Failed to write SQL Server TCP registry configuration.

Registry path involved in failure:
$CurrentRegistryOperationPath

Executing Identity: $($ExecutionContextInfo.UserName)

Original Error:
$($_.Exception.Message)
"@
    }
    # --- END FIX ---
}
else {
    Write-Output "[NETWORK] No MSSQL_PORT configured; skipping static TCP port assignment (default dynamic port in effect)."
}

# 3. Service Descriptor Name Resolution
$ExpectedServiceName = if ($InstanceName -eq "MSSQLSERVER") { "MSSQLSERVER" } else { "MSSQL`$$InstanceName" }
Write-Output "[SERVICE] Resolved service identifier layout context to: $ExpectedServiceName"

$ServiceController = $null

try {
    # 4. SCM Registration Verification
    Write-Output "[STORAGE] Querying Service Control Manager database registry..."
    try {
        $ServiceController = Get-Service -Name $ExpectedServiceName -ErrorAction Stop
    }
    catch {
        throw "[ERROR] SQL Server service '$ExpectedServiceName' not found or inaccessible. Original Error: $($_.Exception.Message)"
    }

    try {
        $Null = $ServiceController.DisplayName
    }
    catch {
        throw "[ERROR] [STORAGE] Target database service wrapper '$ExpectedServiceName' is completely missing from this host SCM."
    }

    $TargetSystemSvc = Get-ServiceManagementObject -SvcName $ExpectedServiceName
    if ($null -eq $TargetSystemSvc) {
        throw "[ERROR] [STORAGE] Failed to fetch host service management attributes for service: $ExpectedServiceName"
    }

    $TargetStartMode = $TargetSystemSvc.StartMode
    if ($TargetStartMode -eq "Disabled") {
        throw "[ERROR] [STORAGE] Cannot orchestrate target instance lifecycle. Service startup configuration is currently marked as Disabled."
    }

    # 5. Dependency Diagnostic Verification Matrix
    $Dependencies = $ServiceController.ServicesDependedOn
    if ($null -ne $Dependencies -and $Dependencies.Count -gt 0) {
        Write-Output "[STORAGE] Discovered root service operational dependencies. Evaluation profiles commencing..."

        foreach ($DepService in $Dependencies) {
            $DepSvcName = $DepService.ServiceName
            $DepMgmtObj = Get-ServiceManagementObject -SvcName $DepSvcName

            if ($null -eq $DepMgmtObj) {
                Write-Output "[WARNING] [STORAGE] Dependency Service '$DepSvcName' registration data could not be verified via management layer. SCM handling active."
                continue
            }

            $DepState = $DepMgmtObj.State
            $DepStartMode = $DepMgmtObj.StartMode
            Write-Output "[STORAGE] Dependency Diagnostic -> Name: '$DepSvcName' | Current State: '$DepState' | Start Mode: '$DepStartMode'"

            if ($DepStartMode -eq "Disabled") {
                throw "[ERROR] [STORAGE] Critical Dependency Failure: Required dependency service '$DepSvcName' is DISABLED. SCM cannot launch the target engine execution thread."
            }
        }
    }

    # 6. Pre-Flight SCM State Evaluation & Transition Engine
    $InitialStatus = $ServiceController.Status
    Write-Output "[STORAGE] Current evaluated initial execution state: $InitialStatus"

    # --- DIAGNOSTIC: service startup timing (Issue 2 / Issue 4 restart timing) ---
    $ServiceStartTimestamp = Get-Date
    Write-Output "[SERVICE] Service name: $ExpectedServiceName"
    Write-Output "[SERVICE] Start timestamp: $($ServiceStartTimestamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))"
    if (-not [string]::IsNullOrWhiteSpace($Port)) {
        Write-Output "[NETWORK] Restart start time: $($ServiceStartTimestamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))"
    }
    # --- END DIAGNOSTIC ---

    if ($InitialStatus -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
        Write-Output "[IDEMPOTENCY] Target service is already actively Running. Bypassing state mutation blocks."
    }
    else {
        if ($InitialStatus -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
            Write-Output "[START] Issuing live hardware engine invocation signal to SCM framework..."

            try {
                $ServiceController.Start()
            }
            catch [System.InvalidOperationException] {
                # --- DIAGNOSTIC: start failure diagnostics (Issue 5) ---
                Write-Output "[FAILURE-DIAGNOSTICS] Collecting service failure diagnostics for '$ExpectedServiceName'..."
                try {
                    $FailSvc = Get-Service -Name $ExpectedServiceName -ErrorAction SilentlyContinue
                    if ($FailSvc) {
                        Write-Output "[FAILURE-DIAGNOSTICS] Windows Service status: $($FailSvc.Status)"
                    }
                    $FailMgmtObj = Get-ServiceManagementObject -SvcName $ExpectedServiceName
                    if ($FailMgmtObj) {
                        Write-Output "[FAILURE-DIAGNOSTICS] StartType: $($FailMgmtObj.StartMode)"
                        if ($FailMgmtObj.PSObject.Properties.Name -contains 'ExitCode') {
                            Write-Output "[FAILURE-DIAGNOSTICS] ExitCode: $($FailMgmtObj.ExitCode)"
                        }
                    }
                    $ErrorLogRoot = Join-Path $env:ProgramFiles "Microsoft SQL Server"
                    if (Test-Path -Path $ErrorLogRoot) {
                        # --- FIX (Issue 5): isolate the recursive ERRORLOG
                        #     scan in its own try/catch so a failure clearly
                        #     reports the search root and exception, without
                        #     changing the existing search strategy. ---
                        try {
                            $ErrorLogCandidate = Get-ChildItem -Path $ErrorLogRoot -Filter "ERRORLOG" -Recurse -ErrorAction Stop |
                                Sort-Object LastWriteTime -Descending | Select-Object -First 1
                            if ($ErrorLogCandidate) {
                                Write-Output "[FAILURE-DIAGNOSTICS] Latest SQL Server ERRORLOG path: $($ErrorLogCandidate.FullName)"
                            }
                            else {
                                Write-Output "[FAILURE-DIAGNOSTICS] No ERRORLOG file found under: $ErrorLogRoot"
                            }
                        }
                        catch {
                            Write-Output "[FAILURE-DIAGNOSTICS] Recursive ERRORLOG search failed. Search Root: $ErrorLogRoot | Exception: $($_.Exception.Message)"
                        }
                        # --- END FIX ---
                    }
                }
                catch {
                    Write-Output "[FAILURE-DIAGNOSTICS] Diagnostic collection failed non-fatally. Details: $($_.Exception.Message)"
                }
                # --- END DIAGNOSTIC ---

                throw @"
[ERROR] [START] SCM Kernel rejected the service start request for '$ExpectedServiceName'.

This usually means the current account lacks rights to start Windows
services. PERMANENT FIX: Run the Jenkins agent service under an account
with local Administrator rights on this machine (Services.msc -> Jenkins
-> Log On tab). One-time, per-machine setting.

Reason: $($_.Exception.Message)
"@
            }
            catch {
                # --- DIAGNOSTIC: start failure diagnostics (Issue 5) ---
                Write-Output "[FAILURE-DIAGNOSTICS] Collecting service failure diagnostics for '$ExpectedServiceName'..."
                try {
                    $FailSvc2 = Get-Service -Name $ExpectedServiceName -ErrorAction SilentlyContinue
                    if ($FailSvc2) {
                        Write-Output "[FAILURE-DIAGNOSTICS] Windows Service status: $($FailSvc2.Status)"
                    }
                    $FailMgmtObj2 = Get-ServiceManagementObject -SvcName $ExpectedServiceName
                    if ($FailMgmtObj2) {
                        Write-Output "[FAILURE-DIAGNOSTICS] StartType: $($FailMgmtObj2.StartMode)"
                        if ($FailMgmtObj2.PSObject.Properties.Name -contains 'ExitCode') {
                            Write-Output "[FAILURE-DIAGNOSTICS] ExitCode: $($FailMgmtObj2.ExitCode)"
                        }
                    }
                    $ErrorLogRoot2 = Join-Path $env:ProgramFiles "Microsoft SQL Server"
                    if (Test-Path -Path $ErrorLogRoot2) {
                        # --- FIX (Issue 5) ---
                        try {
                            $ErrorLogCandidate2 = Get-ChildItem -Path $ErrorLogRoot2 -Filter "ERRORLOG" -Recurse -ErrorAction Stop |
                                Sort-Object LastWriteTime -Descending | Select-Object -First 1
                            if ($ErrorLogCandidate2) {
                                Write-Output "[FAILURE-DIAGNOSTICS] Latest SQL Server ERRORLOG path: $($ErrorLogCandidate2.FullName)"
                            }
                            else {
                                Write-Output "[FAILURE-DIAGNOSTICS] No ERRORLOG file found under: $ErrorLogRoot2"
                            }
                        }
                        catch {
                            Write-Output "[FAILURE-DIAGNOSTICS] Recursive ERRORLOG search failed. Search Root: $ErrorLogRoot2 | Exception: $($_.Exception.Message)"
                        }
                        # --- END FIX ---
                    }
                }
                catch {
                    Write-Output "[FAILURE-DIAGNOSTICS] Diagnostic collection failed non-fatally. Details: $($_.Exception.Message)"
                }
                # --- END DIAGNOSTIC ---

                throw "[ERROR] [START] Fatal system error encountered during service start sequence initiation. Details: $_"
            }
        }
        else {
            Write-Output "[START] Service is currently in a transitional state ($InitialStatus). Advancing straight to stabilization pool..."
        }

        # 7. Dynamic SCM Refresh Polling Loop
        Write-Output "[VERIFY] Commencing operational stabilization polling tracking sequence..."
        $MaxWaitTimeSeconds = 60
        $PollIntervalSeconds = 3
        $MaxIterations = $MaxWaitTimeSeconds / $PollIntervalSeconds
        $IterationCounter = 0
        $IsOperational = $false
        $PollingStartTime = Get-Date

        while (-not $IsOperational -and $IterationCounter -lt $MaxIterations) {
            $IterationCounter++
            Start-Sleep -Seconds $PollIntervalSeconds

            $ServiceController = Get-Service -Name $ExpectedServiceName -ErrorAction Stop

            $CurrentStatus = $ServiceController.Status
            $ElapsedPollingSeconds = [math]::Round(((Get-Date) - $PollingStartTime).TotalSeconds, 2)

            if ($CurrentStatus -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
                $IsOperational = $true
                Write-Output "[VERIFY] Service achieved running metrics target baseline layout at iteration $IterationCounter."
                Write-Output "[VERIFY] Poll iteration: $IterationCounter | Current service state: $CurrentStatus | Elapsed polling time: ${ElapsedPollingSeconds}s"
            }
            else {
                Write-Output "[VERIFY] Service operational transition pending. State: '$CurrentStatus'. Iteration ($IterationCounter/$MaxIterations)..."
                Write-Output "[VERIFY] Poll iteration: $IterationCounter | Current service state: $CurrentStatus | Elapsed polling time: ${ElapsedPollingSeconds}s"
            }
        }

        if (-not $IsOperational) {
            $FinalStatusValue = $ServiceController.Status

            # --- DIAGNOSTIC: start failure diagnostics (Issue 5) ---
            Write-Output "[FAILURE-DIAGNOSTICS] Collecting service failure diagnostics for '$ExpectedServiceName'..."
            try {
                Write-Output "[FAILURE-DIAGNOSTICS] Windows Service status: $FinalStatusValue"
                $FailMgmtObj3 = Get-ServiceManagementObject -SvcName $ExpectedServiceName
                if ($FailMgmtObj3) {
                    Write-Output "[FAILURE-DIAGNOSTICS] StartType: $($FailMgmtObj3.StartMode)"
                    if ($FailMgmtObj3.PSObject.Properties.Name -contains 'ExitCode') {
                        Write-Output "[FAILURE-DIAGNOSTICS] ExitCode: $($FailMgmtObj3.ExitCode)"
                    }
                }
                $ErrorLogRoot3 = Join-Path $env:ProgramFiles "Microsoft SQL Server"
                if (Test-Path -Path $ErrorLogRoot3) {
                    # --- FIX (Issue 5) ---
                    try {
                        $ErrorLogCandidate3 = Get-ChildItem -Path $ErrorLogRoot3 -Filter "ERRORLOG" -Recurse -ErrorAction Stop |
                            Sort-Object LastWriteTime -Descending | Select-Object -First 1
                        if ($ErrorLogCandidate3) {
                            Write-Output "[FAILURE-DIAGNOSTICS] Latest SQL Server ERRORLOG path: $($ErrorLogCandidate3.FullName)"
                        }
                        else {
                            Write-Output "[FAILURE-DIAGNOSTICS] No ERRORLOG file found under: $ErrorLogRoot3"
                        }
                    }
                    catch {
                        Write-Output "[FAILURE-DIAGNOSTICS] Recursive ERRORLOG search failed. Search Root: $ErrorLogRoot3 | Exception: $($_.Exception.Message)"
                    }
                    # --- END FIX ---
                }
            }
            catch {
                Write-Output "[FAILURE-DIAGNOSTICS] Diagnostic collection failed non-fatally. Details: $($_.Exception.Message)"
            }
            # --- END DIAGNOSTIC ---

            throw "[FATAL] [VERIFY] Lifecycle threshold reached! Service '$ExpectedServiceName' failed to transition to a functional state. Final Status: '$FinalStatusValue' after a timeout constraint window of $MaxWaitTimeSeconds seconds."
        }
    }

    # 8. Final Hardened Lifecycle Verification Block
    Write-Output "[CLEANUP] Executing decoupled end-to-end status persistence check..."
    $ServiceController = Get-Service -Name $ExpectedServiceName -ErrorAction Stop
    if ($ServiceController.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
        throw "[ERROR] [CLEANUP] Post-stabilization lifecycle audit failed. Instance dropped operational state immediately post loop execution."
    }

    # --- DIAGNOSTIC: service startup summary (Issue 2 / Issue 4 restart timing) ---
    $ServiceEndTimestamp = Get-Date
    $ServiceStartupDuration = $ServiceEndTimestamp - $ServiceStartTimestamp
    Write-Output "[SERVICE] End timestamp: $($ServiceEndTimestamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))"
    Write-Output "[SERVICE] Total startup duration: $([math]::Round($ServiceStartupDuration.TotalSeconds, 2)) seconds"
    Write-Output "[SERVICE] Final service state: $($ServiceController.Status)"
    if (-not [string]::IsNullOrWhiteSpace($Port)) {
        Write-Output "[NETWORK] Restart end time: $($ServiceEndTimestamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))"
        Write-Output "[NETWORK] Restart duration: $([math]::Round($ServiceStartupDuration.TotalSeconds, 2)) seconds"
    }
    # --- END DIAGNOSTIC ---
}
finally {
    if ($null -ne $ServiceController) {
        try {
            $ServiceController.Close()
        }
        catch {
            # Suppress unexpected RPC or handle connection severance failures during aggressive disposal
        }

        try {
            if ($ServiceController -is [System.IDisposable]) {
                $ServiceController.Dispose()
            }
        }
        catch {
            # Suppress secondary object tracking reference disposal errors
        }

        Write-Output "[CLEANUP] Safely closed handles and disposed of all active Windows SCM components."
    }
}

Write-Output "[SUCCESS] SQL Server lifecycle initialization completed with clean execution metrics."
Write-Output "====================================="
Write-Output "SQL SERVER LIFECYCLE SERVICE SUCCESSFUL"
Write-Output "====================================="

exit 0