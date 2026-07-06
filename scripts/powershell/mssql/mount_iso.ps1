<#
.SYNOPSIS
    DataPlatform-Automation - Storage Platform Extraction Module (Admin-Free)
.DESCRIPTION
    Dynamically identifies, validates, and extracts the SQL Server installation ISO
    using the built-in Windows Shell.Application COM object. Avoids Mount-DiskImage
    AND avoids any external tool dependency (no 7-Zip needed), so no Administrator
    elevation or interactive session is required, and the script behaves identically
    on every machine — no per-laptop software installation drift.
    Enforces idempotency and persists the extraction path for downstream automation.
.NOTES
    Target OS: Windows Server 2019 / 2022 / Windows 10+
    PowerShell Version: 5.1+
    Prerequisite: None (Shell.Application is native to every Windows install)
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ---------------------------------------------------------
# 0. Paths & Config
# ---------------------------------------------------------
$PROJECT_ROOT   = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$DownloadDir    = Join-Path $PROJECT_ROOT "databases\mssql\media"
$ExtractDir     = Join-Path $DownloadDir "extracted"
$TrackingFile   = Join-Path $DownloadDir "mounted_drive.txt"   # kept same filename for downstream compatibility

Write-Output "[INIT] Starting SQL Server ISO extraction phase (no elevation, no external tools)..."

# ---------------------------------------------------------
# 1. Native COM-based ISO extraction function
#    Uses Shell.Application, which ships with every Windows
#    install by default. No 7-Zip, no admin rights, no mount.
# ---------------------------------------------------------
function Expand-IsoNative {
    param(
        [Parameter(Mandatory = $true)][string]$IsoPath,
        [Parameter(Mandatory = $true)][string]$DestinationPath
    )

    $shell = New-Object -ComObject Shell.Application
    try {
        $isoNamespace = $shell.NameSpace($IsoPath)
        if ($null -eq $isoNamespace) {
            throw "[FATAL] Shell.Application could not open ISO namespace for: $IsoPath"
        }

        $destNamespace = $shell.NameSpace($DestinationPath)
        if ($null -eq $destNamespace) {
            throw "[FATAL] Shell.Application could not open destination namespace for: $DestinationPath"
        }

        # 4 = no progress UI, 16 = respond yes to all, 1024 = no UI on error
        $copyFlags = 4 + 16 + 1024
        $destNamespace.CopyHere($isoNamespace.Items(), $copyFlags)

        # CopyHere is asynchronous under the hood for shell namespaces;
        # poll until the expected top-level item count stabilizes.
        $expectedCount = $isoNamespace.Items().Count
        $maxWaitSeconds = 180
        $waited = 0
        while ((Get-ChildItem -Path $DestinationPath -Force | Measure-Object).Count -lt $expectedCount -and $waited -lt $maxWaitSeconds) {
            Start-Sleep -Seconds 2
            $waited += 2
        }
    }
    finally {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
}

# ---------------------------------------------------------
# 2. Media Verification and Corruption Validation
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# 3. Idempotency Check
# ---------------------------------------------------------
$SetupPathCheck = Join-Path $ExtractDir "setup.exe"
$AlreadyExtracted = (Test-Path -Path $ExtractDir) -and (Test-Path -Path $SetupPathCheck)

if ($AlreadyExtracted) {
    Write-Output "[IDEMPOTENCY] ISO already extracted with valid setup.exe present. Skipping re-extraction."
}
else {
    # Clean any partial/stale extraction before retrying
    if (Test-Path -Path $ExtractDir) {
        Write-Output "[CLEANUP] Incomplete extraction detected. Clearing stale extraction directory..."
        Remove-Item -Path $ExtractDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null

    # ---------------------------------------------------------
    # 4. Extraction Execution Phase
    # ---------------------------------------------------------
    Write-Output "[STORAGE] Invoking native COM-based extraction sequence..."
    try {
        Expand-IsoNative -IsoPath $TargetIso.FullName -DestinationPath $ExtractDir
    }
    catch {
        throw "[FATAL] Native ISO extraction failed: $($_.Exception.Message)"
    }
    Write-Output "[STORAGE] Extraction completed successfully."
}

# ---------------------------------------------------------
# 5. Installation Asset Validation Check
# ---------------------------------------------------------
Write-Output "[VALIDATION] Testing structural contents of extracted media..."
if (-not (Test-Path -Path $ExtractDir)) {
    throw "[ERROR] Resolved extraction target path cannot be found or read: $ExtractDir"
}

$SetupPath = Join-Path $ExtractDir "setup.exe"
if (-not (Test-Path -Path $SetupPath)) {
    Write-Output "[CLEANUP] Vital asset 'setup.exe' missing from extracted path. Removing bad extraction..."
    Remove-Item -Path $ExtractDir -Recurse -Force
    throw "[ERROR] Target installation media verification failed. Executable 'setup.exe' is completely missing from root of $ExtractDir"
}
Write-Output "[VALIDATION] Setup vital installation binaries verified present at target location."

# ---------------------------------------------------------
# 6. Atomic State Telemetry Serialization Phase
# ---------------------------------------------------------
Write-Output "[TELEMETRY] Serializing state variable tracking layout contexts..."
if (Test-Path -Path $TrackingFile) {
    Remove-Item -Path $TrackingFile -Force
}

# Downstream install_mssql.ps1 should read this path directly (folder, not a drive letter)
Set-Content -Path $TrackingFile -Value $ExtractDir -Force

# Read back validation
$PersistedValue = (Get-Content -Path $TrackingFile -Raw).Trim()
if ($PersistedValue -ne $ExtractDir) {
    throw "[ERROR] Persistent serialization state corruption detected. Expected: $ExtractDir, Written: $PersistedValue"
}
Write-Output "[TELEMETRY] Deployment token successfully written to cache: $TrackingFile -> ($PersistedValue)"

Write-Output "====================================="
Write-Output "ISO EXTRACTION OPERATIONS SUCCESSFUL"
Write-Output "====================================="

exit 0