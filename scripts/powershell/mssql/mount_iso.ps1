<#
.SYNOPSIS
    DataPlatform-Automation - Storage Platform Loopback Mount Module
.DESCRIPTION
    Dynamically identifies, validates, and mounts the SQL Server installation ISO.
    Enforces true idempotency, handles asynchronous PnP race conditions, and persists
    the device target identifier for downstream automation contexts.
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

Write-Output "[INIT] Starting SQL Server ISO mount phase..."

try {
    Mount-DiskImage -ImagePath $TargetIso.FullName -ErrorAction Stop | Out-Null
}
catch {
    $msg = $_.Exception.Message

    if ($msg -match "Access is denied|administrator|privilege") {
        throw @"
[FATAL]

Windows denied ISO mounting.

Current process is not elevated.

Mount-DiskImage requires Administrator privileges.

Configure Jenkins service to run under an Administrator account
or execute the pipeline from an elevated process.

Original Error:
$msg
"@
    }

    throw
}
# 2. Media Verification and Corruption Validation
if (-not (Test-Path -Path $DownloadDir)) {
    throw "[ERROR] Target media repository folder missing or unreachable: $DownloadDir"
}

$IsoFiles = Get-ChildItem -Path $DownloadDir -Filter "*.iso"
if ($IsoFiles.Count -eq 0) {
    throw "[ERROR] Zero installation ISO payloads detected inside $DownloadDir"
}
if ($IsoFiles.Count -gt 1) {
    throw "[ERROR] Multiple ISO files detected within $DownloadDir. Strict single-ISO policy breached."
}

$TargetIso = $IsoFiles[0]
Write-Output "[MEDIA] Single installation media target resolved: $($TargetIso.FullName)"

if ($TargetIso.Length -lt 1MB) {
    throw "[ERROR] Target installation media file metric checks failed (Size: $($TargetIso.Length) bytes). File appears empty or corrupted."
}
Write-Output "[MEDIA] Pre-flight structural integrity boundary validation passed."

# 3. Idempotency Check (Evaluate Existing Loopback Attachment)
$DiskImage = Get-DiskImage -ImagePath $TargetIso.FullName
$IsMounted = $DiskImage.Attached

$DriveLetterToken = $null

if ($IsMounted) {
    Write-Output "[IDEMPOTENCY] Target ISO volume is already attached to host loopback driver. Querying mount points..."
    
    $MountedVolume = $DiskImage | Get-Volume
    if ($MountedVolume -and -not [string]::IsNullOrEmpty($MountedVolume.DriveLetter)) {
        $DriveLetterToken = "$($MountedVolume.DriveLetter):"
        Write-Output "[IDEMPOTENCY] Re-associated existing mounted disk target to device path: $DriveLetterToken"
    } else {
        Write-Output "[WARNING] Image attached but drive allocation missing. Forcing remount sequence to clear stale storage state..."
        Dismount-DiskImage -ImagePath $TargetIso.FullName | Out-Null
        $IsMounted = $false
    }
}

# 4. Storage Subsystem Execution Phase
if (-not $IsMounted) {
    Write-Output "[STORAGE] Invoking native loopback volume mount sequence..."
    Mount-DiskImage -ImagePath $TargetIso.FullName | Out-Null
    
    # 5. Asynchronous Plug-and-Play Race Condition Mitigation Loop
    $MaxRetries = 15
    $RetryCounter = 0
    $VolumeReady = $false
    
    Write-Output "[STORAGE] Entering hardware device initialization verification polling loop..."
    while (-not $VolumeReady -and $RetryCounter -lt $MaxRetries) {
        $RetryCounter++
        Start-Sleep -Seconds 1
        
        $CurrentVolume = Get-DiskImage -ImagePath $TargetIso.FullName | Get-Volume
        if ($CurrentVolume -and -not [string]::IsNullOrEmpty($CurrentVolume.DriveLetter)) {
            $PotentialDrive = "$($CurrentVolume.DriveLetter):"
            
            # Double-fault check: property allocation and namespace file system availability
            if (Test-Path -Path $PotentialDrive) {
                $DriveLetterToken = $PotentialDrive
                $VolumeReady = $true
                Write-Output "[STORAGE] Storage volume map stabilized successfully on iteration $RetryCounter at target $DriveLetterToken"
            }
        }
    }
    
    if (-not $VolumeReady -or [string]::IsNullOrEmpty($DriveLetterToken)) {
        throw "[FATAL] Asynchronous storage loopback stabilization timeout. Windows PnP manager failed drive allocation."
    }
}

# 6. Installation Asset Validation Check
Write-Output "[VALIDATION] Testing structural contents of target partition layout..."
if (-not (Test-Path -Path $DriveLetterToken)) {
    throw "[ERROR] Resolved system target device location path cannot be found or read: $DriveLetterToken"
}

$SetupPath = Join-Path $DriveLetterToken "setup.exe"
if (-not (Test-Path -Path $SetupPath)) {
    Write-Output "[CLEANUP] Vital asset 'setup.exe' missing from mounted path. Initiating emergency rollback dismount..."
    Dismount-DiskImage -ImagePath $TargetIso.FullName | Out-Null
    throw "[ERROR] Target installation media verification failed. Executable 'setup.exe' is completely missing from root of $DriveLetterToken"
}
Write-Output "[VALIDATION] Setup vital installation binaries verified present at target location."

# 7. Atomic State Telemetry Serialization Phase
Write-Output "[TELEMETRY] Serializing state variable tracking layout contexts..."
if (Test-Path -Path $TrackingFile) {
    Remove-Item -Path $TrackingFile -Force
}

Set-Content -Path $TrackingFile -Value $DriveLetterToken -Force

# Read back validation
$PersistedValue = (Get-Content -Path $TrackingFile -Raw).Trim()
if ($PersistedValue -ne $DriveLetterToken) {
    throw "[ERROR] Persistent serialization state corruption detected. Expected: $DriveLetterToken, Written: $PersistedValue"
}
Write-Output "[TELEMETRY] Deployment token successfully written to cache: $TrackingFile -> ($PersistedValue)"

Write-Output "====================================="
Write-Output "ISO MOUNT OPERATIONS SUCCESSFUL"
Write-Output "====================================="

exit 0