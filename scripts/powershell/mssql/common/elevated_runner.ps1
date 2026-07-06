<#
.SYNOPSIS
    DataPlatform-Automation - Elevated Task Worker
.DESCRIPTION
    Runs as NT AUTHORITY\SYSTEM via a pre-registered Scheduled Task.
    Reads the target script path from a job file, executes it with full
    elevated privileges, and writes the exit code + captured output back
    for the (non-elevated) caller to consume.
.NOTES
    This script is never called directly. It is only ever invoked by the
    "DataPlatformElevatedRunner" Scheduled Task, registered once via
    setup_elevated_task.ps1.
#>

$ErrorActionPreference = 'Stop'
$WorkDir = "C:\ProgramData\DataPlatformAutomation"
$JobFile = Join-Path $WorkDir "job.txt"
$LogFile = Join-Path $WorkDir "job.log"
$ExitFile = Join-Path $WorkDir "job.exitcode"
$DoneFile = Join-Path $WorkDir "job.done"

# Clean any stale completion markers from a previous run before starting
Remove-Item -Path $ExitFile, $DoneFile -Force -ErrorAction SilentlyContinue

if (-not (Test-Path -Path $JobFile)) {
    "9999" | Set-Content -Path $ExitFile -Force
    "[FATAL] No job file found at $JobFile" | Set-Content -Path $LogFile -Force
    "1" | Set-Content -Path $DoneFile -Force
    exit 1
}

$TargetScript = (Get-Content -Path $JobFile -Raw).Trim()

if (-not (Test-Path -Path $TargetScript)) {
    "9999" | Set-Content -Path $ExitFile -Force
    "[FATAL] Target script does not exist: $TargetScript" | Set-Content -Path $LogFile -Force
    "1" | Set-Content -Path $DoneFile -Force
    exit 1
}

try {
    # Execute the real script (mount_iso.ps1, start_mssql.ps1, etc.) with full
    # SYSTEM-level privileges. Output is captured to the log file so the
    # caller can surface it in the Jenkins console.
    $Output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $TargetScript 2>&1
    $ExitCode = $LASTEXITCODE
    if ($null -eq $ExitCode) { $ExitCode = 0 }

    $Output | Out-String | Set-Content -Path $LogFile -Force
    "$ExitCode" | Set-Content -Path $ExitFile -Force
}
catch {
    "$($_.Exception.Message)" | Set-Content -Path $LogFile -Force
    "1" | Set-Content -Path $ExitFile -Force
}
finally {
    "1" | Set-Content -Path $DoneFile -Force
}