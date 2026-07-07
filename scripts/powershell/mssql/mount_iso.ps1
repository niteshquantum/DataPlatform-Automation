<#
.SYNOPSIS
    DataPlatform-Automation - Storage Platform Loopback Mount Module
.DESCRIPTION
    Mounts the SQL Server installation ISO using Mount-DiskImage. Self-elevates
    via the SYSTEM-privileged scheduled task if not already running elevated,
    so Terraform/Jenkins can call this exact file unchanged.
.NOTES
    Target OS: Windows Server 2019 / 2022
    PowerShell Version: 5.1+
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# === ELEVATION AUTO-DISPATCH (do not remove) ===
if ($env:DPA_ELEVATED -ne "1") {
    $InvokeElevated = Join-Path $PSScriptRoot "common\invoke_elevated.ps1"
    if (-not (Test-Path -Path $InvokeElevated)) {
        throw "[FATAL] invoke_elevated.ps1 not found at: $InvokeElevated. Ensure the 'common' folder exists alongside the mssql scripts folder."
    }

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
        throw "[FATAL] Could not resolve powershell.exe on this machine. Checked PATH and $env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe."
    }
    # --- END RESOLVE ---

    & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $InvokeElevated -ScriptPath $PSCommandPath

    # --- Deterministic exit code even if $LASTEXITCODE is null ---
    $DispatchExitCode = 1
    if ($null -ne $LASTEXITCODE) {
        $DispatchExitCode = $LASTEXITCODE
    }
    exit $DispatchExitCode
    # --- END ---
}
# === END ELEVATION AUTO-DISPATCH ===

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$DownloadDir = Join-Path $PROJECT_ROOT "databases\mssql\media"
$TrackingFile = Join-Path $DownloadDir "mounted_drive.txt"

Write-Output "[INIT] Starting SQL Server ISO mount phase (elevated)..."

# 1. Media Verification and Corruption Validation
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

# 2. Idempotency Check (Evaluate Existing Loopback Attachment)
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

# 3. Storage Subsystem Execution Phase
if (-not $IsMounted) {
    Write-Output "[STORAGE] Invoking native loopback volume mount sequence..."
    Mount-DiskImage -ImagePath $TargetIso.FullName | Out-Null

    # --- VERIFY: confirm the image actually reports Attached before polling for a drive letter ---
    $PostMountImage = Get-DiskImage -ImagePath $TargetIso.FullName
    if (-not $PostMountImage.Attached) {
        throw "[FATAL] Mount-DiskImage completed but Get-DiskImage does not report the image as Attached for: $($TargetIso.FullName)"
    }
    # --- END VERIFY ---

    # 4. Asynchronous Plug-and-Play Race Condition Mitigation Loop
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

# 5. Installation Asset Validation Check
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

# --- VERIFY: setup.exe is a non-zero-byte executable ---
$SetupFileInfo = Get-Item -Path $SetupPath
if ($SetupFileInfo.Length -le 0) {
    Write-Output "[CLEANUP] 'setup.exe' found but is zero bytes. Initiating emergency rollback dismount..."
    Dismount-DiskImage -ImagePath $TargetIso.FullName | Out-Null
    throw "[ERROR] Target installation media verification failed. 'setup.exe' at $SetupPath is zero bytes (corrupt or incomplete media)."
}
# --- END VERIFY ---

Write-Output "[VALIDATION] Setup vital installation binaries verified present at target location."

# 6. Atomic State Telemetry Serialization Phase
Write-Output "[TELEMETRY] Serializing state variable tracking layout contexts..."

# --- VERIFY: target directory for mounted_drive.txt is writable ---
$TrackingFileDir = Split-Path -Path $TrackingFile -Parent
if (-not (Test-Path -Path $TrackingFileDir)) {
    throw "[FATAL] Target directory for tracking file does not exist: $TrackingFileDir"
}
$WriteTestFile = Join-Path $TrackingFileDir ".write_test.tmp"
try {
    Set-Content -Path $WriteTestFile -Value "test" -Force -ErrorAction Stop
    Remove-Item -Path $WriteTestFile -Force -ErrorAction Stop
}
catch {
    throw "[FATAL] Target directory is not writable: $TrackingFileDir. Details: $($_.Exception.Message)"
}
# --- END VERIFY ---

if (Test-Path -Path $TrackingFile) {
    Remove-Item -Path $TrackingFile -Force
}

Set-Content -Path $TrackingFile -Value $DriveLetterToken -Force

$PersistedValue = (Get-Content -Path $TrackingFile -Raw).Trim()
if ($PersistedValue -ne $DriveLetterToken) {
    throw "[ERROR] Persistent serialization state corruption detected. Expected: $DriveLetterToken, Written: $PersistedValue"
}
Write-Output "[TELEMETRY] Deployment token successfully written to cache: $TrackingFile -> ($PersistedValue)"

Write-Output "====================================="
Write-Output "ISO MOUNT OPERATIONS SUCCESSFUL"
Write-Output "====================================="

exit 0