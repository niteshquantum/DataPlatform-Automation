<#
.SYNOPSIS
    DataPlatform-Automation - Elevated Execution Dispatcher
.DESCRIPTION
    Triggers the pre-registered "DataPlatformElevatedRunner" Scheduled Task
    to execute a target script with SYSTEM-level privileges, waits for
    completion, streams its output, and exits with the same code the
    target script produced. Use this INSTEAD OF calling admin-requiring
    scripts (mount_iso.ps1, start_mssql.ps1) directly.
.PARAMETER ScriptPath
    Full path to the .ps1 script that needs elevated execution.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File invoke_elevated.ps1 -ScriptPath "C:\...\mount_iso.ps1"
#>

param(
    [Parameter(Mandatory = $true)][string]$ScriptPath
)

$ErrorActionPreference = 'Stop'
$TaskName = "DataPlatformElevatedRunner"
$WorkDir  = "C:\ProgramData\DataPlatformAutomation"
$JobFile  = Join-Path $WorkDir "job.txt"
$LogFile  = Join-Path $WorkDir "job.log"
$ExitFile = Join-Path $WorkDir "job.exitcode"
$DoneFile = Join-Path $WorkDir "job.done"

# --- Centralized diagnostic snapshot helpers (used across all failure paths) ---
function Get-DiagnosticSnapshot {
    $Snap = [ordered]@{
        TaskState            = "unknown"
        LastTaskResult       = "unknown"
        LastRunTime          = "unknown"
        WorkerExecutionStatus = "unknown"
        JobFileExists        = (Test-Path -Path $JobFile)
        DoneFileExists       = (Test-Path -Path $DoneFile)
        ExitFileExists       = (Test-Path -Path $ExitFile)
        LogFileExists        = (Test-Path -Path $LogFile)
    }

    try {
        $CimTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        $CimTaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
        $Snap.TaskState = $CimTask.State.ToString()
        $Snap.LastTaskResult = $CimTaskInfo.LastTaskResult.ToString()
        $Snap.LastRunTime = $CimTaskInfo.LastRunTime.ToString()
    }
    catch {
        try {
            $DiagInfo = & schtasks.exe /query /tn $TaskName /v /fo list 2>&1
            $DiagStatus = ($DiagInfo | Select-String "^Status:\s*(.+)$")
            $DiagLastResult = ($DiagInfo | Select-String "^Last Result:\s*(.+)$")
            $DiagLastRunTime = ($DiagInfo | Select-String "^Last Run Time:\s*(.+)$")
            if ($DiagStatus) { $Snap.TaskState = $DiagStatus.Matches[0].Groups[1].Value.Trim() }
            if ($DiagLastResult) { $Snap.LastTaskResult = $DiagLastResult.Matches[0].Groups[1].Value.Trim() }
            if ($DiagLastRunTime) { $Snap.LastRunTime = $DiagLastRunTime.Matches[0].Groups[1].Value.Trim() }
        }
        catch {
            # Both methods failed - diagnostics remain "unknown", never fatal
        }
    }

    if ($Snap.DoneFileExists) {
        $Snap.WorkerExecutionStatus = "Completed (DoneFile present)"
    }
    elseif ($Snap.TaskState -eq 'Running') {
        $Snap.WorkerExecutionStatus = "In progress (task still running)"
    }
    else {
        $Snap.WorkerExecutionStatus = "Not completed / unknown"
    }

    return $Snap
}

function Format-DiagnosticSnapshot {
    param($Snap)
    return "Task State: $($Snap.TaskState) | Last Result: $($Snap.LastTaskResult) | Last Run Time: $($Snap.LastRunTime) | Worker Status: $($Snap.WorkerExecutionStatus) | JobFile Exists: $($Snap.JobFileExists) | DoneFile Exists: $($Snap.DoneFileExists) | ExitFile Exists: $($Snap.ExitFileExists) | LogFile Exists: $($Snap.LogFileExists)"
}
# --- END diagnostic helpers ---

# --- Shared task-configuration validator used by the auto-bootstrap pre-flight below.
#     Mirrors the validation logic already approved in setup_elevated_task.ps1
#     (Principal, Action, MultipleInstances), the Disabled-state check, a check
#     that the worker script the task points to still exists on disk, and now
#     (this correction) validates the Task Action's Execute path against the
#     FULLY RESOLVED PowerShell executable path per the repository standard
#     resolution order (Get-Command powershell.exe, falling back to
#     %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe), not just
#     the executable's leaf filename. ---
function Test-ElevatedTaskValid {
    param($Task)

    if ($null -eq $Task) { return $false }

    if ($Task.State.ToString() -eq 'Disabled') { return $false }

    $TaskPrincipal = $Task.Principal
    if ($TaskPrincipal.UserId -ne "SYSTEM") { return $false }
    if ($TaskPrincipal.RunLevel.ToString() -ne "Highest") { return $false }

    $TaskAction = $Task.Actions[0]
    if ($null -eq $TaskAction) { return $false }

    # --- FIX (final correction): resolve the expected PowerShell executable
    #     using the repository-standard resolution order, then compare the
    #     Task Action's Execute value against the FULLY RESOLVED path -
    #     not just the leaf filename. ---
    $ResolvedPowerShellExe = $null
    $ResolvedPsCommand = Get-Command "powershell.exe" -ErrorAction SilentlyContinue
    if ($ResolvedPsCommand) {
        $ResolvedPowerShellExe = $ResolvedPsCommand.Source
    }
    if (-not $ResolvedPowerShellExe) {
        $ResolvedFallbackPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        if (Test-Path -Path $ResolvedFallbackPath) {
            $ResolvedPowerShellExe = $ResolvedFallbackPath
        }
    }
    if (-not $ResolvedPowerShellExe) { return $false }

    $TaskActionExecutePath = $TaskAction.Execute
    if ([string]::IsNullOrEmpty($TaskActionExecutePath)) { return $false }

    if ($TaskActionExecutePath -ne $ResolvedPowerShellExe) { return $false }
    # --- END FIX ---

    $ExpectedWorkerPath = Join-Path $WorkDir "elevated_runner.ps1"
    if ($TaskAction.Arguments -notmatch [regex]::Escape($ExpectedWorkerPath)) { return $false }

    # Validation only - confirm the worker script the task's Action actually
    # references still exists on disk. Does not alter task creation logic.
    if (-not (Test-Path -Path $ExpectedWorkerPath)) { return $false }

    # Task is registered with no explicit WorkingDirectory in the current
    # approved definition - validate it hasn't drifted from that default.
    if (-not [string]::IsNullOrEmpty($TaskAction.WorkingDirectory)) { return $false }

    $TaskSettings = $Task.Settings
    if ($TaskSettings.MultipleInstances.ToString() -ne "Queue") { return $false }

    return $true
}

function Get-ElevatedTaskSafe {
    try {
        return Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    }
    catch {
        return $null
    }
}
# --- END FIX ---

# 0. Pre-flight: confirm the elevated task is registered and correctly configured.
# --- FIX (Automation Enhancement): if the task is missing or misconfigured,
#     automatically invoke setup_elevated_task.ps1 instead of requiring a human
#     to run it manually first. If the current context lacks the Administrator
#     rights that setup_elevated_task.ps1 itself requires, its existing admin
#     check still throws its existing, detailed diagnostic message - no UAC
#     bypass is introduced here. ---
$ElevatedTaskCheck = Get-ElevatedTaskSafe
$ElevatedTaskValid = Test-ElevatedTaskValid -Task $ElevatedTaskCheck

if ($null -eq $ElevatedTaskCheck) {
    Write-Output "[ELEVATED] Elevated task '$TaskName' not found. Attempting automatic bootstrap..."
}
elseif (-not $ElevatedTaskValid) {
    Write-Output "[ELEVATED] Elevated task '$TaskName' exists but is misconfigured. Attempting automatic bootstrap/repair..."
}
else {
    Write-Output "[ELEVATED] Elevated task '$TaskName' found and correctly configured."
}

if ($null -eq $ElevatedTaskCheck -or -not $ElevatedTaskValid) {
    $SetupScriptPath = Join-Path $PSScriptRoot "setup_elevated_task.ps1"
    if (-not (Test-Path -Path $SetupScriptPath)) {
        throw "[FATAL] Automatic bootstrap failed: setup_elevated_task.ps1 not found at expected path: $SetupScriptPath"
    }

    # --- Resolve the PowerShell executable using the repository-standard
    #     resolution order, instead of assuming powershell.exe is on PATH. ---
    $PowerShellExe = $null
    $PsCommand = Get-Command "powershell.exe" -ErrorAction SilentlyContinue
    if ($PsCommand) {
        $PowerShellExe = $PsCommand.Source
    }
    if (-not $PowerShellExe) {
        $FallbackPath = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        if (Test-Path -Path $FallbackPath) {
            $PowerShellExe = $FallbackPath
        }
    }
    if (-not $PowerShellExe) {
        throw "[FATAL] Could not resolve powershell.exe on this machine. Checked PATH and $env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe."
    }
    # --- END ---

    Write-Output "[ELEVATED] Invoking automatic bootstrap: $SetupScriptPath"
    $BootstrapOutput = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $SetupScriptPath 2>&1
    $BootstrapExitCode = $LASTEXITCODE
    $BootstrapOutput | ForEach-Object { Write-Output "[BOOTSTRAP] $_" }

    # --- Report only real diagnostics on bootstrap failure. No instruction
    #     to manually run setup_elevated_task.ps1 or any other script - the
    #     [BOOTSTRAP] output above already carries the underlying reason
    #     from setup_elevated_task.ps1 itself. ---
    if ($BootstrapExitCode -ne 0) {
        throw "[FATAL] Automatic bootstrap of elevated task '$TaskName' failed (exit code $BootstrapExitCode). See [BOOTSTRAP] output above for the underlying reason."
    }
    # --- END ---

    # Re-check after the bootstrap attempt.
    $ElevatedTaskCheck = Get-ElevatedTaskSafe
    $ElevatedTaskValid = Test-ElevatedTaskValid -Task $ElevatedTaskCheck

    if ($null -eq $ElevatedTaskCheck) {
        throw "[FATAL] Automatic bootstrap completed but elevated task '$TaskName' still could not be found. Check Task Scheduler and the [BOOTSTRAP] output above."
    }
    if (-not $ElevatedTaskValid) {
        throw "[FATAL] Automatic bootstrap completed but elevated task '$TaskName' is still not correctly configured. Check Task Scheduler and the [BOOTSTRAP] output above."
    }

    Write-Output "[ELEVATED] Automatic bootstrap succeeded. Elevated task '$TaskName' is now registered and correctly configured."
}
# --- END FIX ---

# --- Pre-flight: verify task is enabled/ready before proceeding ---
try {
    $PreflightTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    if ($PreflightTask.State.ToString() -eq 'Disabled') {
        throw "[FATAL] Elevated task '$TaskName' exists but is DISABLED. Enable it in Task Scheduler before running this pipeline."
    }
}
catch {
    if ($_.Exception.Message -like "*is DISABLED*") { throw }
    # Get-ScheduledTask unavailable/failed - fall back to schtasks detailed query
    try {
        $PreflightDetail = & schtasks.exe /query /tn $TaskName /v /fo list 2>&1
        $PreflightStatusLine = ($PreflightDetail | Select-String "^Status:\s*(.+)$")
        if ($PreflightStatusLine -and $PreflightStatusLine.Matches[0].Groups[1].Value.Trim() -eq 'Disabled') {
            throw "[FATAL] Elevated task '$TaskName' exists but is DISABLED. Enable it in Task Scheduler before running this pipeline."
        }
    }
    catch {
        if ($_.Exception.Message -like "*is DISABLED*") { throw }
        # Could not determine enabled/ready state via either method - non-fatal, continue
        Write-Output "[ELEVATED] Pre-flight: could not confirm task enabled/ready state; continuing."
    }
}
# --- END pre-flight task state check ---

if (-not (Test-Path -Path $ScriptPath)) {
    throw "[FATAL] Target script not found: $ScriptPath"
}

# --- Pre-flight: fail fast if the repository worker script path is wrong ---
$PreflightWorkerSource = Join-Path $PSScriptRoot "elevated_runner.ps1"
if (-not (Test-Path -Path $PreflightWorkerSource)) {
    throw "[FATAL] Repository worker script not found (pre-flight check): $PreflightWorkerSource"
}
# --- END pre-flight worker path check ---

if (-not (Test-Path -Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}

# --- Pre-flight: confirm the work directory is actually writable ---
try {
    $PreflightProbe = Join-Path $WorkDir "._writetest_$([guid]::NewGuid().ToString('N')).tmp"
    Set-Content -Path $PreflightProbe -Value "test" -Force -ErrorAction Stop
    Remove-Item -Path $PreflightProbe -Force -ErrorAction SilentlyContinue
}
catch {
    throw "[FATAL] Work directory is not accessible/writable: $WorkDir. Exception: $($_.Exception.Message)"
}
# --- END pre-flight work directory accessibility check ---

$Mutex = New-Object System.Threading.Mutex($false, "Global\DataPlatformElevatedMutex")
$LockAcquired = $false
try {
    Write-Output "[ELEVATED] Waiting for exclusive access to the elevated runner (in case another step is using it)..."
    $LockAcquired = $Mutex.WaitOne(300000)
    if (-not $LockAcquired) {
        throw "[FATAL] Could not acquire the elevated runner lock within 5 minutes. Current Script :
$ScriptPath

Task :
DataPlatformElevatedRunner. Check Task Scheduler history for 'DataPlatformElevatedRunner'."
    }

    # --- VERIFY + SELF-HEAL: staged worker must match repository worker ---
    # Single refresh path only: direct Copy-Item -Force, then re-verify hash.
    # This dispatcher never invokes setup_elevated_task.ps1 for the worker
    # refresh itself and never generates any temporary refresh scripts or
    # scheduled-task-based copy fallback.
    $WorkerScriptSource = Join-Path $PSScriptRoot "elevated_runner.ps1"
    $WorkerScriptTarget = Join-Path $WorkDir "elevated_runner.ps1"

    if (-not (Test-Path -Path $WorkerScriptSource)) {
        throw "[FATAL] Repository worker script not found: $WorkerScriptSource"
    }

    try {
        $SourceHash = (Get-FileHash -Path $WorkerScriptSource -Algorithm SHA256 -ErrorAction Stop).Hash
    }
    catch {
        throw "[FATAL] Failed to compute hash for repository worker script. Path: $WorkerScriptSource. Exception: $($_.Exception.Message)"
    }

    $TargetExists = Test-Path -Path $WorkerScriptTarget
    $NeedsCopy = $true

    if ($TargetExists) {
        try {
            $TargetHash = (Get-FileHash -Path $WorkerScriptTarget -Algorithm SHA256 -ErrorAction Stop).Hash
        }
        catch {
            throw "[FATAL] Failed to compute hash for staged worker script. Path: $WorkerScriptTarget. Exception: $($_.Exception.Message)"
        }
        $NeedsCopy = ($SourceHash -ne $TargetHash)
    }

    if ($NeedsCopy) {
        if (-not $TargetExists) {
            Write-Output "[SELF-HEAL] Staged worker not found. Copying automatically..."
        }
        else {
            Write-Output "[SELF-HEAL] Staged worker is out of date relative to the repository. Copying automatically..."
        }

        # --- Ensure destination directory exists before copying ---
        $WorkerScriptTargetDir = Split-Path -Path $WorkerScriptTarget -Parent
        if (-not (Test-Path -Path $WorkerScriptTargetDir)) {
            New-Item -ItemType Directory -Path $WorkerScriptTargetDir -Force | Out-Null
        }
        # --- END ---

        try {
            Copy-Item -Path $WorkerScriptSource -Destination $WorkerScriptTarget -Force -ErrorAction Stop
        }
        catch {
            throw @"
[FATAL] Automatic worker copy failed.
Source      : $WorkerScriptSource
Destination : $WorkerScriptTarget
Exception   : $($_.Exception.Message)
"@
        }

        if (-not (Test-Path -Path $WorkerScriptTarget)) {
            throw @"
[FATAL] Automatic worker copy did not produce a destination file.
Source      : $WorkerScriptSource
Destination : $WorkerScriptTarget
"@
        }

        # Brief settle delay to avoid reading the destination file's hash
        # before the filesystem has fully flushed the just-completed copy.
        Start-Sleep -Milliseconds 300

        try {
            $TargetHash = (Get-FileHash -Path $WorkerScriptTarget -Algorithm SHA256 -ErrorAction Stop).Hash
        }
        catch {
            throw "[FATAL] Failed to compute hash for staged worker script after copy. Path: $WorkerScriptTarget. Exception: $($_.Exception.Message)"
        }

        if ($SourceHash -ne $TargetHash) {
            throw @"
[FATAL] Worker copy verification failed: hash mismatch after copy.
Source      : $WorkerScriptSource ($SourceHash)
Destination : $WorkerScriptTarget ($TargetHash)
"@
        }

        Write-Output "[SELF-HEAL] Staged worker verified up to date after copy."
    }
    # --- END VERIFY + SELF-HEAL ---

    # 1. Clear any stale job state and hand off the new job
    Remove-Item -Path $JobFile, $ExitFile, $DoneFile, $LogFile `
    -Force `
    -ErrorAction SilentlyContinue
    Set-Content -Path $JobFile -Value $ScriptPath -Force -Encoding UTF8

    if (-not (Test-Path -Path $JobFile)) {
        throw "[FATAL] Job handoff failed: $JobFile was not created."
    }
    $WrittenJobContent = (Get-Content -Path $JobFile -Raw).Trim()
    if ($WrittenJobContent -ne $ScriptPath) {
        throw "[FATAL] Job handoff verification failed. Expected: '$ScriptPath', Found: '$WrittenJobContent'."
    }

    $DispatchStartTime = Get-Date
    Write-Output "[ELEVATED] Dispatch start time: $($DispatchStartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Output "[ELEVATED] Dispatching '$ScriptPath' to SYSTEM-privileged task runner..."

    $RunOutput = & schtasks.exe /run /tn $TaskName 2>&1
    if ($LASTEXITCODE -ne 0) {
        $FailSnap = Get-DiagnosticSnapshot
        throw "[FATAL] Failed to trigger elevated task '$TaskName'. schtasks output: $RunOutput. Diagnostics -> $(Format-DiagnosticSnapshot $FailSnap)"
    }

    Start-Sleep -Seconds 2
    try {
        $PostRunQuery = & schtasks.exe /query /tn $TaskName /v /fo list 2>&1
        $StatusLine = ($PostRunQuery | Select-String "^Status:\s*(.+)$")
        if ($StatusLine) {
            $ObservedStatus = $StatusLine.Matches[0].Groups[1].Value.Trim()
            Write-Output "[ELEVATED] Post-dispatch task status: $ObservedStatus"
        }
        else {
            Write-Output "[ELEVATED] Post-dispatch task status could not be determined (non-English locale or unexpected output format); continuing normally."
        }
    }
    catch {
        Write-Output "[ELEVATED] Post-dispatch status check skipped due to an error: $($_.Exception.Message)"
    }

    # 2. Wait for the worker to signal completion
    $MaxWaitSeconds = 600
    $Waited = 0
    while (-not (Test-Path -Path $DoneFile) -and $Waited -lt $MaxWaitSeconds) {
        Start-Sleep -Seconds 2
        $Waited += 2
        if (($Waited % 30) -eq 0) {
            Write-Output "[ELEVATED] Still waiting for elevated task to complete... Elapsed: ${Waited}s / ${MaxWaitSeconds}s"
        }
    }

    if (-not (Test-Path -Path $DoneFile)) {
        $TimeoutSnap = Get-DiagnosticSnapshot
        $DiagText = Format-DiagnosticSnapshot $TimeoutSnap

        throw "[FATAL] Elevated task did not complete within $MaxWaitSeconds seconds. Check Task Scheduler history for '$TaskName'. Diagnostics -> $DiagText"
    }

    $DispatchEndTime = Get-Date
    $TotalDuration = $DispatchEndTime - $DispatchStartTime
    Write-Output "[ELEVATED] Dispatch end time: $($DispatchEndTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Output "[ELEVATED] Wait duration: $Waited seconds"
    Write-Output "[ELEVATED] Total execution duration: $([math]::Round($TotalDuration.TotalSeconds, 2)) seconds"

    # 3. Surface the captured output and exit code
    if (-not (Test-Path -Path $ExitFile)) {
        $ExitMissingSnap = Get-DiagnosticSnapshot
        throw "[FATAL] Task signalled completion (DoneFile present) but ExitFile is missing: $ExitFile. Diagnostics -> $(Format-DiagnosticSnapshot $ExitMissingSnap)"
    }
    $RawExitContent = (Get-Content -Path $ExitFile -Raw).Trim()
    $ParsedExitCode = 0
    if (-not [int]::TryParse($RawExitContent, [ref]$ParsedExitCode)) {
        $BadExitSnap = Get-DiagnosticSnapshot
        throw "[FATAL] ExitFile does not contain a valid integer. Found: '$RawExitContent' in $ExitFile. Diagnostics -> $(Format-DiagnosticSnapshot $BadExitSnap)"
    }
    if (-not (Test-Path -Path $LogFile)) {
        Write-Output "[WARNING] Task completed but LogFile was not found: $LogFile"
    }

    if (Test-Path -Path $LogFile) {
        Get-Content -Path $LogFile -ReadCount 100 | ForEach-Object { $_ }
    }

    $ExitCode = $ParsedExitCode
}
finally {
    if ($LockAcquired) {
        $Mutex.ReleaseMutex()
    }
    $Mutex.Dispose()
}

exit $ExitCode