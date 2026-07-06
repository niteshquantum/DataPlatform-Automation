<#
.SYNOPSIS
    DataPlatform-Automation - One-Time Elevated Task Bootstrap
.DESCRIPTION
    Registers a Scheduled Task ("DataPlatformElevatedRunner") that runs as
    NT AUTHORITY\SYSTEM with highest privileges, on-demand (no schedule).
    Once registered, the pipeline can silently execute admin-requiring
    scripts (ISO mount/extract, SQL service start, registry config) without
    any further manual intervention, without needing a UAC prompt, and
    WITHOUT changing the Jenkins service Log On account (so no other
    pipeline is affected).
.NOTES
    RUN THIS ONCE PER MACHINE, FROM AN ELEVATED POWERSHELL (Run as Administrator).
    After this one-time setup, everything downstream is fully automatic.
#>

$ErrorActionPreference = 'Stop'

# 0. Confirm we are actually elevated right now (this script itself needs
#    admin rights ONCE, to register the task).
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    throw "[SETUP ERROR] This bootstrap script must be run once from an elevated ('Run as Administrator') PowerShell window. Right-click PowerShell -> Run as Administrator, then re-run this script."
}

$TaskName = "DataPlatformElevatedRunner"
$WorkDir  = "C:\ProgramData\DataPlatformAutomation"

# 1. Prepare working directory for job hand-off files
if (-not (Test-Path -Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}

# 2. Copy the worker script into a stable, version-independent location
#    so the Scheduled Task action never breaks if the repo folder moves.
$WorkerScriptSource = Join-Path $PSScriptRoot "elevated_runner.ps1"
$WorkerScriptTarget = Join-Path $WorkDir "elevated_runner.ps1"

if (-not (Test-Path -Path $WorkerScriptSource)) {
    throw "[SETUP ERROR] elevated_runner.ps1 not found next to this bootstrap script at: $WorkerScriptSource"
}
Copy-Item -Path $WorkerScriptSource -Destination $WorkerScriptTarget -Force

Write-Output "[SETUP] Worker script staged at: $WorkerScriptTarget"

# 3. Register the Scheduled Task (idempotent - safe to re-run)
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Output "[SETUP] Task '$TaskName' already exists. Removing and re-registering to ensure a clean definition..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$WorkerScriptTarget`""

$Principal = New-ScheduledTaskPrincipal `
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
    -Principal $Principal `
    -Settings $Settings `
    -Description "DataPlatform-Automation: on-demand elevated runner for Jenkins pipeline steps requiring Administrator privileges (SQL Server service control, registry config)." `
    -Force | Out-Null

# 4. Grant "Authenticated Users" read + execute rights on this specific task.
#    By default, a SYSTEM-owned task's security descriptor restricts query/run
#    access to Administrators only. Without this, any non-admin caller
#    (Jenkins, Terraform local-exec, etc.) gets "Access is denied" when
#    trying to query or trigger the task, even though the task itself runs
#    fine once triggered.
Write-Output "[SETUP] Granting Authenticated Users execute rights on the task..."
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
    Write-Output "[SETUP] Access rights updated - any authenticated account can now query/trigger this task."
}
else {
    Write-Output "[SETUP] Access rights already correctly configured."
}

Write-Output "====================================="
Write-Output "ONE-TIME BOOTSTRAP COMPLETE"
Write-Output "====================================="
Write-Output "Task '$TaskName' is registered to run as SYSTEM, on-demand."
Write-Output "No further manual steps are required on this machine."
Write-Output "The Jenkins service account itself was NOT modified - other pipelines are unaffected."