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

    # 1. Clear any stale job state and hand off the new job
    Remove-Item -Path $ExitFile, $DoneFile, $LogFile -Force -ErrorAction SilentlyContinue
    Set-Content -Path $JobFile -Value $ScriptPath -Force

    Write-Output "[ELEVATED] Dispatching '$ScriptPath' to SYSTEM-privileged task runner..."
    $RunOutput = & schtasks.exe /run /tn $TaskName 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "[FATAL] Failed to trigger elevated task '$TaskName'. schtasks output: $RunOutput"
    }

    # 2. Wait for the worker to signal completion
    $MaxWaitSeconds = 600
    $Waited = 0
    while (-not (Test-Path -Path $DoneFile) -and $Waited -lt $MaxWaitSeconds) {
        Start-Sleep -Seconds 2
        $Waited += 2
    }

    if (-not (Test-Path -Path $DoneFile)) {
        throw "[FATAL] Elevated task did not complete within $MaxWaitSeconds seconds. Check Task Scheduler history for '$TaskName'."
    }

    # 3. Surface the captured output and exit code
    if (Test-Path -Path $LogFile) {
        Get-Content -Path $LogFile
    }

    $ExitCode = 1
    if (Test-Path -Path $ExitFile) {
        $ExitCode = [int](Get-Content -Path $ExitFile -Raw).Trim()
    }
}
finally {
    if ($LockAcquired) {
        $Mutex.ReleaseMutex()
    }
    $Mutex.Dispose()
}

exit $ExitCode