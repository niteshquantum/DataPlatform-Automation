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
        TaskState             = "unknown"
        LastTaskResult        = "unknown"
        LastRunTime           = "unknown"
        WorkerExecutionStatus = "unknown"
        JobFileExists         = (Test-Path -Path $JobFile)
        DoneFileExists        = (Test-Path -Path $DoneFile)
        ExitFileExists        = (Test-Path -Path $ExitFile)
        LogFileExists         = (Test-Path -Path $LogFile)
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
function Test-ElevatedTaskValid {
    param($Task)

    if ($null -eq $Task) { return $false }

    if ($Task.State.ToString() -eq 'Disabled') { return $false }

    $TaskPrincipal = $Task.Principal
    if ($TaskPrincipal.UserId -ne "SYSTEM") { return $false }
    if ($TaskPrincipal.RunLevel.ToString() -ne "Highest") { return $false }

    $TaskAction = $Task.Actions[0]
    if ($null -eq $TaskAction) { return $false }

    $TaskActionExecutePath = $TaskAction.Execute
    if ([string]::IsNullOrEmpty($TaskActionExecutePath)) { return $false }

    $ExecuteName = Split-Path -Path $TaskActionExecutePath -Leaf
    if ($ExecuteName -notmatch '(?i)^powershell\.exe$')
    {
        return $false
    }

    $ExpectedWorkerPath = Join-Path $WorkDir "elevated_runner.ps1"
    if ($TaskAction.Arguments -notmatch [regex]::Escape($ExpectedWorkerPath)) { return $false }

    if (-not (Test-Path -Path $ExpectedWorkerPath)) { return $false }

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
# --- END ---

# 0. Pre-flight: confirm the elevated task is registered and correctly configured.
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

    Write-Output "[ELEVATED] Invoking automatic bootstrap: $SetupScriptPath"
    $BootstrapOutput = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $SetupScriptPath 2>&1
    $BootstrapExitCode = $LASTEXITCODE
    $BootstrapOutput | ForEach-Object { Write-Output "[BOOTSTRAP] $_" }

    if ($BootstrapExitCode -ne 0) {
        throw "[FATAL] Automatic bootstrap of elevated task '$TaskName' failed (exit code $BootstrapExitCode). See [BOOTSTRAP] output above for the underlying reason."
    }

    $MaxRetries = 3
    $RetryDelaySeconds = 2
    for ($i = 1; $i -le $MaxRetries; $i++) {
        $ElevatedTaskCheck = Get-ElevatedTaskSafe
        $ElevatedTaskValid = Test-ElevatedTaskValid -Task $ElevatedTaskCheck
        if ($ElevatedTaskCheck -and $ElevatedTaskValid) {
            break
        }
        if ($i -lt $MaxRetries) {
            Write-Output "[ELEVATED] Post-bootstrap validation failed on attempt $i. Retrying in $RetryDelaySeconds seconds..."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    if ($null -eq $ElevatedTaskCheck) {
        throw "[FATAL] Automatic bootstrap completed but elevated task '$TaskName' still could not be found. Check Task Scheduler and the [BOOTSTRAP] output above."
    }
    if (-not $ElevatedTaskValid) {
        throw "[FATAL] Automatic bootstrap completed but elevated task '$TaskName' is still not correctly configured. Check Task Scheduler and the [BOOTSTRAP] output above."
    }

    Write-Output "[ELEVATED] Automatic bootstrap succeeded. Elevated task '$TaskName' is now registered and correctly configured."
}

# --- Pre-flight: verify task is enabled/ready before proceeding ---
try {
    $PreflightTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    if ($PreflightTask.State.ToString() -eq 'Disabled') {
        throw "[FATAL] Elevated task '$TaskName' exists but is DISABLED. Enable it in Task Scheduler before running this pipeline."
    }
}
catch {
    if ($_.Exception.Message -like "*is DISABLED*") { throw }
    try {
        $PreflightDetail = & schtasks.exe /query /tn $TaskName /v /fo list 2>&1
        $PreflightStatusLine = ($PreflightDetail | Select-String "^Status:\s*(.+)$")
        if ($PreflightStatusLine -and $PreflightStatusLine.Matches[0].Groups[1].Value.Trim() -eq 'Disabled') {
            throw "[FATAL] Elevated task '$TaskName' exists but is DISABLED. Enable it in Task Scheduler before running this pipeline."
        }
    }
    catch {
        if ($_.Exception.Message -like "*is DISABLED*") { throw }
        Write-Output "[ELEVATED] Pre-flight: could not confirm task enabled/ready state; continuing."
    }
}
# --- END ---

if (-not (Test-Path -Path $ScriptPath)) {
    throw "[FATAL] Target script not found: $ScriptPath"
}

$PreflightWorkerSource = Join-Path $PSScriptRoot "elevated_runner.ps1"
if (-not (Test-Path -Path $PreflightWorkerSource)) {
    throw "[FATAL] Repository worker script not found (pre-flight check): $PreflightWorkerSource"
}

if (-not (Test-Path -Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}

# --- Pre-flight: check (non-fatally) whether the work directory is directly
#     writable by this process. This is informational only - the self-heal
#     section below already has a Tier-2 fallback (routing writes through
#     the SYSTEM-privileged task) for machines where this account cannot
#     write here directly, so this check must NOT abort the run. ---
try {
    $PreflightProbe = Join-Path $WorkDir "._writetest_$([guid]::NewGuid().ToString('N')).tmp"
    Set-Content -Path $PreflightProbe -Value "test" -Force -ErrorAction Stop
    Remove-Item -Path $PreflightProbe -Force -ErrorAction SilentlyContinue
    Write-Output "[ELEVATED] Pre-flight: work directory is directly writable by this account."
}
catch {
    Write-Output "[ELEVATED] Pre-flight: work directory is NOT directly writable by this account ($($_.Exception.Message)). This is expected on some machines - the elevated-task copy fallback will be used instead."
}
# --- END ---

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

        $WorkerScriptTargetDir = Split-Path -Path $WorkerScriptTarget -Parent
        if (-not (Test-Path -Path $WorkerScriptTargetDir)) {
            New-Item -ItemType Directory -Path $WorkerScriptTargetDir -Force | Out-Null
        }

        $RefreshSucceeded = $false

        # Tier 1: direct copy. Works whenever this account already has
        # write access to the staging folder (varies by machine's ACL).
        try {
            Copy-Item -Path $WorkerScriptSource -Destination $WorkerScriptTarget -Force -ErrorAction Stop
            $RefreshSucceeded = $true
            Write-Output "[SELF-HEAL] Staged worker refreshed via direct copy."
        }
        catch {
            Write-Output "[SELF-HEAL] Direct copy did not succeed (expected if this account lacks write access to $WorkDir on this machine): $($_.Exception.Message)"
        }

        # Tier 2: if direct copy was denied, route the copy through the
        # SYSTEM-privileged scheduled task itself, which always has write
        # access to its own staging folder regardless of the calling
        # account's permissions. This is what makes the refresh work
        # identically on every machine, regardless of that machine's
        # particular folder-permission defaults.
        if (-not $RefreshSucceeded) {
            Write-Output "[SELF-HEAL] Retrying refresh via the SYSTEM-privileged scheduled task..."

            $RefreshScriptPath = Join-Path $WorkDir "_refresh_worker.ps1"
            $RefreshScriptContent = @"
`$ErrorActionPreference = 'Stop'
Copy-Item -Path '$WorkerScriptSource' -Destination '$WorkerScriptTarget' -Force
exit 0
"@
            Set-Content -Path $RefreshScriptPath -Value $RefreshScriptContent -Force -Encoding UTF8

            Remove-Item -Path $ExitFile, $DoneFile, $LogFile -Force -ErrorAction SilentlyContinue
            Set-Content -Path $JobFile -Value $RefreshScriptPath -Force -Encoding UTF8

            $RefreshRunOutput = & schtasks.exe /run /tn $TaskName 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "[FATAL] Self-heal could not trigger the elevated task to refresh the staged worker. schtasks output: $RefreshRunOutput"
            }

            $RefreshWaited = 0
            $RefreshMaxWaitSeconds = 60
            while (-not (Test-Path -Path $DoneFile) -and $RefreshWaited -lt $RefreshMaxWaitSeconds) {
                Start-Sleep -Seconds 2
                $RefreshWaited += 2
            }

            if (Test-Path -Path $DoneFile) {
                $RefreshSucceeded = $true
                Write-Output "[SELF-HEAL] Staged worker refresh dispatched and completed via elevated task."
            }
            else {
                Write-Output "[SELF-HEAL] Elevated refresh attempt did not signal completion within $RefreshMaxWaitSeconds seconds."
            }

            Remove-Item -Path $RefreshScriptPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $ExitFile, $DoneFile, $LogFile -Force -ErrorAction SilentlyContinue
        }

        if (-not (Test-Path -Path $WorkerScriptTarget)) {
            throw "[FATAL] Self-heal failed: staged worker still missing at $WorkerScriptTarget after both direct-copy and elevated-task-copy attempts."
        }

        Start-Sleep -Milliseconds 300

        try {
            $TargetHash = (Get-FileHash -Path $WorkerScriptTarget -Algorithm SHA256 -ErrorAction Stop).Hash
        }
        catch {
            throw "[FATAL] Failed to compute hash for staged worker script after copy. Path: $WorkerScriptTarget. Exception: $($_.Exception.Message)"
        }

        if ($SourceHash -ne $TargetHash) {
            throw @"
[FATAL] Self-heal failed: staged worker at $WorkerScriptTarget still does not match the
repository version at $WorkerScriptSource, after both a direct-copy attempt and an
elevated-task copy attempt.

This indicates a permissions or file-lock problem on:
  $WorkDir
(for example: the folder's ACL denies writes even to SYSTEM, the file is held open
by another process, or the volume is write-protected).

Verify that $WorkDir is writable by SYSTEM, then re-run the pipeline. This is not
expected in normal operation and points to a machine-specific configuration issue.
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