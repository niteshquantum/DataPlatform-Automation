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

# 0. Pre-flight: confirm the one-time bootstrap has been done on this machine
# NOTE: Using schtasks.exe (native binary) instead of Get-ScheduledTask,
# because the ScheduledTasks PowerShell module can silently fail to
# autoload in stripped execution environments (e.g. Terraform local-exec,
# Jenkins spawned processes) where PSModulePath is not fully populated.
$TaskCheckOutput = & schtasks.exe /query /tn $TaskName 2>&1
$TaskExists = ($LASTEXITCODE -eq 0)

if (-not $TaskExists) {
    throw @"
[FATAL] Elevated task '$TaskName' is not registered on this machine.

ONE-TIME SETUP REQUIRED (only once, ever, per machine):
  1. Open PowerShell as Administrator (right-click -> Run as Administrator)
  2. Run: .\setup_elevated_task.ps1

After this one-time step, every future pipeline run on this machine is
fully automatic - no manual action needed again.
"@
}

if (-not (Test-Path -Path $ScriptPath)) {
    throw "[FATAL] Target script not found: $ScriptPath"
}

if (-not (Test-Path -Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}

# Global system-wide lock: ensures only ONE elevated request is in flight at
# any time, across ALL scripts and ALL concurrent Terraform/Jenkins calls on
# this machine. Without this, two near-simultaneous requests could collide
# on the same shared job files and cause one of them to hang forever.
$Mutex = New-Object System.Threading.Mutex($false, "Global\DataPlatformElevatedMutex")
$LockAcquired = $false
try {
    Write-Output "[ELEVATED] Waiting for exclusive access to the elevated runner (in case another step is using it)..."
    $LockAcquired = $Mutex.WaitOne(300000)  # wait up to 5 minutes for the lock itself
    if (-not $LockAcquired) {
        throw "[FATAL] Could not acquire the elevated runner lock within 5 minutes. Another elevated step appears to be stuck. Check Task Scheduler history for 'DataPlatformElevatedRunner'."
    }

    # --- VERIFY: staged worker must match repository worker (read-only check) ---
    # NOTE: This process (Jenkins/non-elevated account) does NOT have write
    # access to C:\ProgramData\DataPlatformAutomation, which is owned by
    # SYSTEM/Administrator. Therefore this dispatcher can only VERIFY the
    # staged worker; it must never attempt to copy/overwrite it. If the
    # staged copy is missing or out of date, fail fast with clear guidance
    # instead of silently running a stale worker or crashing on access-denied.
    $WorkerScriptSource = Join-Path $PSScriptRoot "elevated_runner.ps1"
    $WorkerScriptTarget = Join-Path $WorkDir "elevated_runner.ps1"

    if (-not (Test-Path -Path $WorkerScriptSource)) {
        throw "[FATAL] Repository worker script not found: $WorkerScriptSource"
    }
    if (-not (Test-Path -Path $WorkerScriptTarget)) {
        throw @"
[FATAL] Staged worker script not found: $WorkerScriptTarget

ONE-TIME SETUP REQUIRED (only once, ever, per machine):
  1. Open PowerShell as Administrator (right-click -> Run as Administrator)
  2. Run: .\setup_elevated_task.ps1
"@
    }

    $SourceHash = (Get-FileHash -Path $WorkerScriptSource -Algorithm SHA256).Hash
    $TargetHash = (Get-FileHash -Path $WorkerScriptTarget -Algorithm SHA256).Hash

    if ($SourceHash -ne $TargetHash) {
        throw @"
[FATAL] Worker script is out of date.
Staged copy ($WorkerScriptTarget) does not match the repository version ($WorkerScriptSource).

Run setup_elevated_task.ps1 (as Administrator) to refresh the staged worker:
  1. Open PowerShell as Administrator (right-click -> Run as Administrator)
  2. Run: .\setup_elevated_task.ps1
"@
    }
    # --- END VERIFY ---

    # 1. Clear any stale job state and hand off the new job
    Remove-Item -Path $ExitFile, $DoneFile, $LogFile -Force -ErrorAction SilentlyContinue
    Set-Content -Path $JobFile -Value $ScriptPath -Force

    # --- VERIFY: job handoff actually succeeded ---
    if (-not (Test-Path -Path $JobFile)) {
        throw "[FATAL] Job handoff failed: $JobFile was not created."
    }
    $WrittenJobContent = (Get-Content -Path $JobFile -Raw).Trim()
    if ($WrittenJobContent -ne $ScriptPath) {
        throw "[FATAL] Job handoff verification failed. Expected: '$ScriptPath', Found: '$WrittenJobContent'."
    }
    # --- END VERIFY ---

    Write-Output "[ELEVATED] Dispatching '$ScriptPath' to SYSTEM-privileged task runner..."

    $RunOutput = & schtasks.exe /run /tn $TaskName 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "[FATAL] Failed to trigger elevated task '$TaskName'. schtasks output: $RunOutput"
    }

    # --- DIAGNOSTIC: best-effort post-dispatch status check (non-fatal) ---
    # NOTE: schtasks /query output labels are locale-dependent; this parsing
    # is best-effort only and must never fail the run if it doesn't match.
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
    # --- END DIAGNOSTIC ---

    # 2. Wait for the worker to signal completion
    $MaxWaitSeconds = 600
    $Waited = 0
    while (-not (Test-Path -Path $DoneFile) -and $Waited -lt $MaxWaitSeconds) {
        Start-Sleep -Seconds 2
        $Waited += 2
    }

    if (-not (Test-Path -Path $DoneFile)) {
        # --- DIAGNOSTICS: capture task state before failing (locale-independent, best-effort) ---
        $DiagCurrentStatus = "unknown"
        $DiagLastResultVal = "unknown"
        $DiagLastRunTimeVal = "unknown"

        # Primary: Get-ScheduledTask / Get-ScheduledTaskInfo expose fixed
        # (non-localized) object properties, unlike schtasks.exe text output.
        try {
            $CimTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            $CimTaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction Stop
            $DiagCurrentStatus = $CimTask.State.ToString()
            $DiagLastResultVal = $CimTaskInfo.LastTaskResult.ToString()
            $DiagLastRunTimeVal = $CimTaskInfo.LastRunTime.ToString()
        }
        catch {
            # Fallback: schtasks.exe text parsing (English-locale only, best-effort)
            try {
                $DiagInfo = & schtasks.exe /query /tn $TaskName /v /fo list 2>&1
                $DiagStatus = ($DiagInfo | Select-String "^Status:\s*(.+)$")
                $DiagLastResult = ($DiagInfo | Select-String "^Last Result:\s*(.+)$")
                $DiagLastRunTime = ($DiagInfo | Select-String "^Last Run Time:\s*(.+)$")
                if ($DiagStatus) { $DiagCurrentStatus = $DiagStatus.Matches[0].Groups[1].Value.Trim() }
                if ($DiagLastResult) { $DiagLastResultVal = $DiagLastResult.Matches[0].Groups[1].Value.Trim() }
                if ($DiagLastRunTime) { $DiagLastRunTimeVal = $DiagLastRunTime.Matches[0].Groups[1].Value.Trim() }
            }
            catch {
                # Both methods failed - diagnostics remain "unknown", never fatal
            }
        }

        $DiagText = "Current Status: $DiagCurrentStatus | Last Result: $DiagLastResultVal | Last Run Time: $DiagLastRunTimeVal"
        # --- END DIAGNOSTICS ---

        throw "[FATAL] Elevated task did not complete within $MaxWaitSeconds seconds. Check Task Scheduler history for '$TaskName'. Diagnostics -> $DiagText"
    }

    # 3. Surface the captured output and exit code
    # --- VERIFY: completion signalling is complete and well-formed ---
    if (-not (Test-Path -Path $ExitFile)) {
        throw "[FATAL] Task signalled completion (DoneFile present) but ExitFile is missing: $ExitFile"
    }
    $RawExitContent = (Get-Content -Path $ExitFile -Raw).Trim()
    $ParsedExitCode = 0
    if (-not [int]::TryParse($RawExitContent, [ref]$ParsedExitCode)) {
        throw "[FATAL] ExitFile does not contain a valid integer. Found: '$RawExitContent' in $ExitFile"
    }
    if (-not (Test-Path -Path $LogFile)) {
        Write-Output "[WARNING] Task completed but LogFile was not found: $LogFile"
    }
    # --- END VERIFY ---

    if (Test-Path -Path $LogFile) {
        Get-Content -Path $LogFile
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