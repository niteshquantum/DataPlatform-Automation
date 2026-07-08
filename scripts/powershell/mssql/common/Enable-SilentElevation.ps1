<#
.SYNOPSIS
    DataPlatform-Automation - One-time host bootstrap: enable silent elevation
    for local Administrators group accounts (no interactive UAC prompt).
.DESCRIPTION
    Run this ONCE per build/agent machine, as part of your existing machine
    provisioning automation (VM image bake, Ansible, Packer, DSC, or a manual
    one-time setup step in your agent bootstrap process). This is NOT run per
    pipeline execution — it is a one-time host configuration, same category
    as installing Jenkins itself.

    After this runs, any process started under an Administrators-group
    account (e.g. NITESH\Admin) can self-elevate via
    'Start-Process ... -Verb RunAs' with ZERO interactive prompt, forever,
    on that machine — which is what makes start_mssql.ps1's self-elevation
    bootstrap work fully automatically on every pipeline run afterward.

    This script itself must be run from an elevated (Administrator) PowerShell
    session ONE TIME. This is unavoidable: some elevated action must occur at
    least once per machine to configure the machine to allow silent elevation
    thereafter. This is standard practice for build-agent provisioning.
.NOTES
    Target OS: Windows Server 2019 / 2022
#>
$ErrorActionPreference = 'Stop'

$Identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object System.Security.Principal.WindowsPrincipal($Identity)
$IsElevated = $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsElevated) {
    throw "[ERROR] This one-time bootstrap script must be run from an elevated (Run as Administrator) PowerShell session. Executing Identity: $($Identity.Name)"
}

$PolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

Write-Output "[BOOTSTRAP] Configuring silent elevation for Administrators group on this host..."
Write-Output "[BOOTSTRAP] Executing Identity: $($Identity.Name) (elevated: $IsElevated)"

# ConsentPromptBehaviorAdmin = 0  ->  "Elevate without prompting"
# This applies only to accounts in the built-in Administrators group.
# Standard (non-admin) users are completely unaffected and still get the
# normal UAC credential prompt.
Set-ItemProperty -Path $PolicyPath -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force

$VerifyValue = (Get-ItemProperty -Path $PolicyPath -Name "ConsentPromptBehaviorAdmin").ConsentPromptBehaviorAdmin
if ($VerifyValue -ne 0) {
    throw "[ERROR] [BOOTSTRAP] Verification failed. ConsentPromptBehaviorAdmin expected 0, found '$VerifyValue'."
}

Write-Output "[BOOTSTRAP] ConsentPromptBehaviorAdmin set to 0 (Elevate without prompting) and verified."
Write-Output "[BOOTSTRAP] Silent elevation is now enabled for Administrators-group accounts on this host."
Write-Output "[BOOTSTRAP] This is a one-time, per-machine setting. No further action needed on this host."
Write-Output "[SUCCESS] Host bootstrap complete."