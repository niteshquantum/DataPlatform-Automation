<#
.SYNOPSIS
    DataPlatform-Automation - Self-Healing Elevated Task Bootstrap
.DESCRIPTION
    Registers (or repairs) a Scheduled Task ("DataPlatformElevatedRunner")
    that runs as NT AUTHORITY\SYSTEM with highest privileges, on-demand
    (no schedule). Once registered, the pipeline can silently execute
    admin-requiring scripts (ISO mount/extract, SQL service start, registry
    config) without any further manual intervention, without needing a
    UAC prompt, and WITHOUT changing the Jenkins service Log On account
    (so no other pipeline is affected).
.NOTES
    SELF-HEALING: This script is safe to run on every machine setup and,
    if desired, on every pipeline run. It does NOT unconditionally delete
    and recreate the task. It only takes corrective action where something
    is actually missing, outdated, or misconfigured:
      - Task missing         -> Register
      - Task exists, correct -> Leave as-is
      - Task exists, wrong   -> Re-register (only the mismatched parts)
      - Worker outdated      -> Refresh worker in place
      - Permissions missing  -> Repair permissions
    Must be run from an elevated context, since registering/repairing a
    SYSTEM-owned task requires Administrator privileges.
    This script may also be invoked automatically by invoke_elevated.ps1
    when it detects the task is missing or misconfigured; in that case it
    still requires the calling context to already hold Administrator
    rights - no elevation is performed here.
#>

$ErrorActionPreference = 'Stop'

# 0. Confirm we are actually elevated right now (this script itself needs
#    admin rights, to register/repair the task).
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    throw @"
[SETUP ERROR] Administrator privileges are required to register a SYSTEM scheduled task.

CURRENT CONTEXT (for diagnostics):
  Running as user  : $($Identity.Name)
  Is Administrator : False

This script will now stop. No changes have been made.
"@
}

$TaskName = "DataPlatformElevatedRunner"
$WorkDir  = "C:\ProgramData\DataPlatformAutomation"

# 1. Prepare working directory for job hand-off files
if (-not (Test-Path -Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}

# --- VERIFY: work directory exists and is writable ---
if (-not (Test-Path -Path $WorkDir)) {
    throw "[SETUP ERROR] Work directory could not be created or found: $WorkDir"
}
$TestFile = Join-Path $WorkDir ".write_test.tmp"
try {
    Set-Content -Path $TestFile -Value "test" -Force -ErrorAction Stop
    Remove-Item -Path $TestFile -Force -ErrorAction Stop
}
catch {
    throw "[SETUP ERROR] Work directory is not writable: $WorkDir. Details: $($_.Exception.Message)"
}
# --- END VERIFY ---

# --- FIX (Automatic ACL repair): grant "Authenticated Users" Modify rights on
#     the work directory (and all files within it, recursively), so that a
#     non-elevated caller (Jenkins, Terraform local-exec, invoke_elevated.ps1)
#     can read/write job hand-off files (job.txt, job.log, job.exitcode,
#     job.done) created by the SYSTEM-privileged worker without hitting
#     UnauthorizedAccessException. Uses icacls, which is safe to re-run:
#     re-granting an ACE that is already present does not fail or duplicate
#     it. This runs every time (self-healing), same pattern as the existing
#     Scheduled Task permission repair in Step 4 below. ---
Write-Output "[SETUP] Verifying Authenticated Users Modify rights on work directory: $WorkDir..."
$IcaclsOutput = & icacls.exe $WorkDir /grant "Authenticated Users:(OI)(CI)M" /T 2>&1
$IcaclsExitCode = $LASTEXITCODE
if ($IcaclsExitCode -ne 0) {
    throw @"
[SETUP ERROR] Failed to grant Authenticated Users Modify rights on work directory.

Work Directory : $WorkDir
icacls ExitCode : $IcaclsExitCode
icacls Output    : $IcaclsOutput
"@
}
Write-Output "[SETUP] Work directory permissions verified/repaired - non-elevated callers can read/write job hand-off files."
# --- END FIX ---

# 2. Self-heal the worker script: refresh only if outdated or missing.
#    (This script runs elevated, so unlike invoke_elevated.ps1 it IS allowed
#    to write into $WorkDir.)
$WorkerScriptSource = Join-Path $PSScriptRoot "elevated_runner.ps1"
$WorkerScriptTarget = Join-Path $WorkDir "elevated_runner.ps1"

if (-not (Test-Path -Path $WorkerScriptSource)) {
    throw "[SETUP ERROR] elevated_runner.ps1 not found next to this bootstrap script at: $WorkerScriptSource"
}

$SourceHash = (Get-FileHash -Path $WorkerScriptSource -Algorithm SHA256).Hash
$WorkerNeedsRefresh = $true
if (Test-Path -Path $WorkerScriptTarget) {
    $TargetHash = (Get-FileHash -Path $WorkerScriptTarget -Algorithm SHA256).Hash
    $WorkerNeedsRefresh = ($SourceHash -ne $TargetHash)
}

if ($WorkerNeedsRefresh) {
    Write-Output "[SETUP] Worker script missing or outdated. Refreshing..."
    Copy-Item -Path $WorkerScriptSource -Destination $WorkerScriptTarget -Force

    # --- VERIFY: worker copy actually succeeded ---
    if (-not (Test-Path -Path $WorkerScriptTarget)) {
        throw "[SETUP ERROR] Worker script copy failed. Destination does not exist: $WorkerScriptTarget"
    }
    $WorkerScriptTargetItem = Get-Item -Path $WorkerScriptTarget
    if ($WorkerScriptTargetItem.Length -le 0) {
        throw "[SETUP ERROR] Worker script copy produced an empty file: $WorkerScriptTarget"
    }
    $PostCopyHash = (Get-FileHash -Path $WorkerScriptTarget -Algorithm SHA256).Hash
    if ($PostCopyHash -ne $SourceHash) {
        throw "[SETUP ERROR] Worker script refresh verification failed: hash mismatch after copy. Source: $WorkerScriptSource, Target: $WorkerScriptTarget"
    }
    # --- END VERIFY ---

    Write-Output "[SETUP] Worker script refreshed at: $WorkerScriptTarget"
}
else {
    Write-Output "[SETUP] Worker script already up to date at: $WorkerScriptTarget"
}

# --- FIX (Correction 2): resolve the PowerShell executable using the same
#     resolution logic already approved elsewhere in the repository
#     (mount_iso.ps1 / invoke_elevated.ps1), instead of assuming
#     powershell.exe is on PATH. Used below for the Scheduled Task Action. ---
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
    throw "[SETUP ERROR] Could not resolve powershell.exe on this machine. Checked PATH and $env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe."
}
# --- END FIX ---

# 3. Self-healing task registration.
#    Only register/re-register when the task is genuinely missing or
#    genuinely misconfigured - never unconditionally delete-and-recreate.
$ExpectedArgument = "-NoProfile -ExecutionPolicy Bypass -File `"$WorkerScriptTarget`""

function Test-TaskConfigurationValid {
    param($Task)

    if ($null -eq $Task) { return $false }

    $TaskPrincipal = $Task.Principal
    if ($TaskPrincipal.UserId -ne "SYSTEM") { return $false }
    if ($TaskPrincipal.RunLevel.ToString() -ne "Highest") { return $false }

    $TaskAction = $Task.Actions[0]
    if ($null -eq $TaskAction) { return $false }

    $ExecuteName = Split-Path -Path $TaskAction.Execute -Leaf
    if ($ExecuteName -notmatch '(?i)^powershell\.exe$') { return $false }

    if ($TaskAction.Arguments -notmatch [regex]::Escape($WorkerScriptTarget)) { return $false }

    $TaskSettings = $Task.Settings
    if ($TaskSettings.MultipleInstances.ToString() -ne "Queue") { return $false }

    return $true
}

$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
$TaskIsValid = Test-TaskConfigurationValid -Task $ExistingTask

if ($null -eq $ExistingTask) {
    Write-Output "[SETUP] Task '$TaskName' not found. Registering..."
}
elseif (-not $TaskIsValid) {
    Write-Output "[SETUP] Task '$TaskName' exists but configuration does not match expected values. Re-registering..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}
else {
    Write-Output "[SETUP] Task '$TaskName' already exists and is correctly configured. No changes needed."
}

if ($null -eq $ExistingTask -or -not $TaskIsValid) {
    # --- FIX (Correction 2): use the resolved PowerShell executable path
    #     instead of the hardcoded literal "powershell.exe". ---
    $Action = New-ScheduledTaskAction `
        -Execute $PowerShellExe `
        -Argument $ExpectedArgument
    # --- END FIX ---

    $TaskPrincipalObj = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest

    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -MultipleInstances Queue `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Principal $TaskPrincipalObj `
        -Settings $Settings `
        -Description "DataPlatform-Automation: on-demand elevated runner for Jenkins pipeline steps requiring Administrator privileges (SQL Server service control, registry config)." `
        -Force | Out-Null

    Write-Output "[SETUP] Task '$TaskName' registered."
}

# --- VERIFY: task exists and configuration matches expected values ---
$VerifyTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($null -eq $VerifyTask) {
    throw "[SETUP ERROR] Task '$TaskName' registration could not be verified. Get-ScheduledTask returned nothing."
}

$VerifyPrincipal = $VerifyTask.Principal
if ($VerifyPrincipal.UserId -ne "SYSTEM") {
    throw "[SETUP ERROR] Task principal mismatch. Expected UserId 'SYSTEM', found '$($VerifyPrincipal.UserId)'."
}
if ($VerifyPrincipal.RunLevel.ToString() -ne "Highest") {
    throw "[SETUP ERROR] Task RunLevel mismatch. Expected 'Highest', found '$($VerifyPrincipal.RunLevel.ToString())'."
}

$VerifyAction = $VerifyTask.Actions[0]
$VerifyExecuteName = Split-Path -Path $VerifyAction.Execute -Leaf
if ($VerifyExecuteName -notmatch '(?i)^powershell\.exe$') {
    throw "[SETUP ERROR] Task Execute mismatch. Expected an executable named 'powershell.exe', found '$($VerifyAction.Execute)'."
}
if ($VerifyAction.Arguments -notmatch [regex]::Escape($WorkerScriptTarget)) {
    throw "[SETUP ERROR] Task Arguments do not reference expected worker script path: $WorkerScriptTarget"
}
# --- END VERIFY ---

# 4. Self-heal "Authenticated Users" read + execute rights on this specific
#    task. By default, a SYSTEM-owned task's security descriptor restricts
#    query/run access to Administrators only. Without this, any non-admin
#    caller (Jenkins, Terraform local-exec, etc.) gets "Access is denied"
#    when trying to query or trigger the task, even though the task itself
#    runs fine once triggered. This check runs every time and repairs the
#    permission if it's ever missing (e.g. after a Windows update resets
#    task ACLs), rather than assuming it's still in place from before.
Write-Output "[SETUP] Verifying Authenticated Users execute rights on the task..."
$TaskService = New-Object -ComObject Schedule.Service
$TaskService.Connect()
$RootFolder = $TaskService.GetFolder("\")
$RegisteredTask = $RootFolder.GetTask("\$TaskName")

# SECURITY_INFORMATION flag 4 = DACL only
$CurrentSddl = $RegisteredTask.GetSecurityDescriptor(4)

# Append an ACE granting Authenticated Users (AU) generic read (GR) and
# generic execute (GX) rights, only if not already present.
if ($CurrentSddl -notmatch '\(A;;GRGX;;;AU\)') {
    $NewSddl = $CurrentSddl + "(A;;GRGX;;;AU)"
    $RegisteredTask.SetSecurityDescriptor($NewSddl, 0)
    Write-Output "[SETUP] Access rights were missing and have been repaired - any authenticated account can now query/trigger this task."
}
else {
    Write-Output "[SETUP] Access rights already correctly configured."
}

Write-Output "====================================="
Write-Output "SELF-HEALING BOOTSTRAP COMPLETE"
Write-Output "====================================="
Write-Output "Task '$TaskName' is registered to run as SYSTEM, on-demand, and correctly configured."
Write-Output "This script is safe to re-run at any time (idempotent) - it only changes what is actually missing or incorrect."
Write-Output "The Jenkins service account itself was NOT modified - other pipelines are unaffected."

# --- Explicit terminal exit code so callers that invoke this script via
#     'powershell.exe -File' (e.g. the auto-bootstrap path in
#     invoke_elevated.ps1) have a deterministic success signal via
#     $LASTEXITCODE, rather than relying on whatever native command last
#     set it. ---
exit 0