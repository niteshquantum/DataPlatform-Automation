<#
.SYNOPSIS
    DataPlatform-Automation - Storage Platform Loopback Dismount Module
.DESCRIPTION
    Safely and idempotently removes the mounted SQL Server installation media ISO.
    Enforces elevated permissions, clears asynchronous loopback states, and purges
    the local tracking state cache files cleanly.
.NOTES
    Target OS: Windows Server 2019 / 2022
    PowerShell Version: 5.1+
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Define strict relative paths based on repository freeze structure
$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$DownloadDir = Join-Path $PROJECT_ROOT "databases\mssql\media"
$TrackingFile = Join-Path $DownloadDir "mounted_drive.txt"

Write-Output "[INIT] Starting SQL Server ISO cleanup/dismount phase..."

# 1. Pre-Flight Administrator Context Security Validation
Write-Output "[SECURITY] Initializing elevated context security validation..."
$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    throw "[ERROR] [SECURITY] Elevated Administrator privileges are strictly required to execute loopback volume dismounting."
}
Write-Output "[SECURITY] Verified execution context runs with elevated administrative privileges."

# 2. Media Folder and Target Payload Verification
Write-Output "[MEDIA] Resolving localized storage media components..."
if (-not (Test-Path -Path $DownloadDir)) {
    throw "[ERROR] [MEDIA] Target media repository folder missing or unreachable: $DownloadDir"
}

$IsoFiles = Get-ChildItem -Path $DownloadDir -Filter "*.iso"
if ($IsoFiles.Count -eq 0) {
    throw "[ERROR] [MEDIA] Zero installation ISO payloads detected inside $DownloadDir. Cannot determine dismount targets."
}
if ($IsoFiles.Count -gt 1) {
    throw "[ERROR] [MEDIA] Multiple ISO files detected within $DownloadDir. Strict single-ISO policy breached."
}

$TargetIso = $IsoFiles[0]
Write-Output "[MEDIA] Single installation media target resolved for cleanup: $($TargetIso.FullName)"

# 3. Storage Subsystem Execution Phase (Idempotent Handle Tracking)
Write-Output "[STORAGE] Querying active host loopback attachment layouts..."
$IsMounted = $false

try {
    # Microsoft Storage documentation behavior: Get-DiskImage can throw structural exceptions 
    # if metadata is uninitialized or detached after host system reboots.
    $DiskImage = Get-DiskImage -ImagePath $TargetIso.FullName -ErrorAction Stop
    $IsMounted = $DiskImage.Attached
}
catch {
    Write-Output "[STORAGE] Target image metadata unavailable or already unattached. Defaulting tracking state to unmounted."
    $IsMounted = $false
}

if ($IsMounted) {
    Write-Output "[DISMOUNT] Triggering native loopback device teardown pipeline..."
    try {
        Dismount-DiskImage -ImagePath $TargetIso.FullName | Out-Null
        Write-Output "[DISMOUNT] Native unmount operation issued successfully to the driver pool."
    }
    catch {
        throw "[ERROR] [DISMOUNT] Native Dismount-DiskImage operation failed to execute for image: $($TargetIso.FullName). Details: $_"
    }
    
    # 4. Asynchronous Teardown Verification Polling Loop
    Write-Output "[VERIFY] Entering Virtual Disk Service (VDS) verification polling loop..."
    $MaxRetries = 15
    $PollIntervalSeconds = 2
    $IterationCounter = 0
    $DismountComplete = $false
    
    while (-not $DismountComplete -and $IterationCounter -lt $MaxRetries) {
        $IterationCounter++
        Start-Sleep -Seconds $PollIntervalSeconds
        
        $CheckAttached = $true
        try {
            $CheckDiskImage = Get-DiskImage -ImagePath $TargetIso.FullName -ErrorAction Stop
            $CheckAttached = $CheckDiskImage.Attached
        }
        catch {
            # Object dropping out of storage visibility implies successful unmounting driver separation
            $CheckAttached = $false
        }
        
        # Dual-Layer Validation: Verify both back-end loopback attachment context AND front-end volume mapping absence
        $VolumeObjectExists = $false
        if (Test-Path -Path $TrackingFile) {
            $CachedDrive = (Get-Content -Path $TrackingFile -Raw).Trim()
            if (-not [string]::IsNullOrEmpty($CachedDrive)) {
                $CleanLetter = $CachedDrive.Replace(":", "")
                $VolumeCheck = Get-Volume -DriveLetter $CleanLetter -ErrorAction SilentlyContinue
                if ($null -ne $VolumeCheck -or (Test-Path -Path $CachedDrive)) {
                    $VolumeObjectExists = $true
                }
            }
        }
        
        if (-not $CheckAttached -and -not $VolumeObjectExists) {
            $DismountComplete = $true
            Write-Output "[VERIFY] Core volume mapping and device handle completely cleared. State stabilized on iteration $IterationCounter."
        }
        else {
            Write-Output "[VERIFY] Asynchronous VDS volume hooks still lingering. Iteration ($IterationCounter/$MaxRetries). Retrying..."
        }
    }
    
    if (-not $DismountComplete) {
        throw "[FATAL] [VERIFY] Asynchronous storage teardown threshold breached. Windows storage manager failed to release the disk layout safely."
    }
}
else {
    Write-Output "[DISMOUNT] Target installation media is already unattached. Skipping hardware interaction phases."
}

# 5. Atomic State Tracking File Cleanup
Write-Output "[CLEANUP] Synchronizing tracking metadata records..."
try {
    if (Test-Path -Path $TrackingFile) {
        if (-not $IsMounted) {
            Write-Output "[CLEANUP] Stale tracking state detected ('mounted_drive.txt' exists but ISO is already unattached)."
        }
        Write-Output "[CLEANUP] Purging tracking metadata payload: $TrackingFile"
        Remove-Item -Path $TrackingFile -Force
        
        # Immediate post-delete file system assertion
        if (Test-Path -Path $TrackingFile) {
            throw "[ERROR] [CLEANUP] File-system write block encountered. Unable to remove tracking file target lock: '$TrackingFile'."
        }
        Write-Output "[CLEANUP] State tracking storage records cleared successfully."
    }
    else {
        Write-Output "[CLEANUP] State file 'mounted_drive.txt' is absent. Environment state remains clean."
    }
}
catch {
    throw "[ERROR] [CLEANUP] Fatal execution interruption occurred during infrastructure cleanup phase. Details: $_"
}

Write-Output "[SUCCESS] Media dismount operations completed with absolute success metrics."
Write-Output "====================================="
Write-Output "ISO DISMOUNT OPERATIONS SUCCESSFUL"
Write-Output "====================================="

exit 0