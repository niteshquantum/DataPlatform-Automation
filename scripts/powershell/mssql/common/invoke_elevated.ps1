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

# --- Helper: write the exit code file and verify it landed correctly ---
function Write-ExitFile {
    param([int]$Code)
    "$Code" | Set-Content -Path $ExitFile -Force
    if (-not (Test-Path -Path $ExitFile)) {
        try { "[WARNING] Failed to create ExitFile: $ExitFile" | Add-Content -Path $LogFile -Force -ErrorAction SilentlyContinue } catch {}
        return
    }
    $Verify = (Get-Content -Path $ExitFile -Raw -ErrorAction SilentlyContinue).Trim()
    $ParsedCheck = 0
    if (-not [int]::TryParse($Verify, [ref]$ParsedCheck)) {
        try { "[WARNING] ExitFile did not contain a valid integer after write. Found: '$Verify'" | Add-Content -Path $LogFile -Force -ErrorAction SilentlyContinue } catch {}
    }
}

# --- Helper: write the log file and verify it is readable ---
function Write-LogFile {
    param([string]$Content)
    $Content | Set-Content -Path $LogFile -Force
    if (-not (Test-Path -Path $LogFile)) {
        return
    }
    try {
        $null = Get-Content -Path $LogFile -Raw -ErrorAction Stop
    }
    catch {
        # Log file exists but isn't readable; nothing further to do.
    }
}

# --- Helper: signal completion and verify it was actually created ---
function Write-DoneFile {
    $Attempts = 0
    $Created = $false
    while (-not $Created -and $Attempts -lt 3) {
        $Attempts++
        try {
            "1" | Set-Content -Path $DoneFile -Force -ErrorAction Stop
            if (Test-Path -Path $DoneFile) {
                $Created = $true
            }
        }
        catch {
            Start-Sleep -Milliseconds 200
        }
    }
    if (-not $Created) {
        try {
            "[FATAL] elevated_runner.ps1 could not create DoneFile at $DoneFile after $Attempts attempts. The caller (invoke_elevated.ps1) will time out waiting for this file." | Add-Content -Path $LogFile -Force -ErrorAction SilentlyContinue
        }
        catch {}
    }
}

# Clean any stale completion markers from a previous run before starting
Remove-Item -Path $ExitFile, $DoneFile -Force -ErrorAction SilentlyContinue

# --- VALIDATE: job.txt must exist and contain a non-empty, non-whitespace path ---
if (-not (Test-Path -Path $JobFile)) {
    Write-LogFile "[FATAL] No job file found at $JobFile"
    Write-ExitFile 9999
    Write-DoneFile
    exit 1
}

$TargetScript = (Get-Content -Path $JobFile -Raw -ErrorAction SilentlyContinue)
if ($null -ne $TargetScript) { $TargetScript = $TargetScript.Trim() }

if ([string]::IsNullOrWhiteSpace($TargetScript)) {
    Write-LogFile "[FATAL] Job file $JobFile exists but contains an empty or whitespace-only script path."
    Write-ExitFile 9999
    Write-DoneFile
    exit 1
}

if (-not (Test-Path -Path $TargetScript)) {
    Write-LogFile "[FATAL] Target script does not exist: $TargetScript"
    Write-ExitFile 9999
    Write-DoneFile
    exit 1
}
# --- END VALIDATE ---

# --- RESOLVE: locate the PowerShell executable instead of assuming it's on PATH ---
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
    Write-LogFile "[FATAL] Could not resolve powershell.exe on this machine. Checked PATH and $env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe."
    Write-ExitFile 9999
    Write-DoneFile
    exit 1
}
# --- END RESOLVE ---

$ExitCode = 1  # deterministic default; only ever overwritten by a real result below

try {
    $env:DPA_ELEVATED = "1"

    # --- VERIFY: target script still exists immediately before execution ---
    if (-not (Test-Path -Path $TargetScript)) {
        throw "[FATAL] Target script disappeared before execution could start: $TargetScript"
    }
    # --- END VERIFY ---

    # Execute the real script (mount_iso.ps1, start_mssql.ps1, etc.) with full
    # SYSTEM-level privileges. Output is captured to the log file so the
    # caller can surface it in the Jenkins console.
    #
    # IMPORTANT: temporarily relax ErrorActionPreference to 'Continue' for
    # just this invocation. With 'Stop' in effect, ANY text the child
    # process writes to its error stream (stderr) - even benign status
    # output from setup.exe or a non-fatal warning inside the target
    # script - gets promoted by PowerShell into a script-terminating
    # exception here, aborting the whole elevated run and masking the
    # real result with a confusing "term not recognized" style message.
    # 'Continue' captures that output as plain text (via 2>&1) without
    # treating it as fatal; the actual success/failure of the target
    # script is still determined purely by its real process exit code
    # ($LASTEXITCODE) immediately below, so no failure detection is lost.
    $PreviousEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $Output = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $TargetScript 2>&1
    $ErrorActionPreference = $PreviousEap

    # --- Deterministic exit-code resolution ---
    if ($null -ne $LASTEXITCODE) {
        $ExitCode = $LASTEXITCODE
    }
    else {
        $ExitCode = 0
    }
    # --- END ---

    Write-LogFile ($Output | Out-String)
    Write-ExitFile $ExitCode
}
catch {
    # --- Full diagnostics on failure (not just Exception.Message) ---
    $ErrObj = $_
    $DiagLines = @()
    $DiagLines += "[FATAL] elevated_runner.ps1 failed while executing target script: $TargetScript"
    $DiagLines += "Exception: $($ErrObj.Exception.GetType().FullName): $($ErrObj.Exception.Message)"
    if ($ErrObj.InvocationInfo) {
        $DiagLines += "ScriptName: $($ErrObj.InvocationInfo.ScriptName)"
        $DiagLines += "LineNumber: $($ErrObj.InvocationInfo.ScriptLineNumber)"
        $DiagLines += "Line: $($ErrObj.InvocationInfo.Line)"
        $DiagLines += "PositionMessage: $($ErrObj.InvocationInfo.PositionMessage)"
    }
    if ($ErrObj.ScriptStackTrace) {
        $DiagLines += "StackTrace:`n$($ErrObj.ScriptStackTrace)"
    }
    Write-LogFile ($DiagLines -join "`n")
    $ExitCode = 1
    Write-ExitFile $ExitCode
    # --- END DIAGNOSTICS ---
}
finally {
    Write-DoneFile
}

exit $ExitCode