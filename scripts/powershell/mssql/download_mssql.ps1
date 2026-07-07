<#
.SYNOPSIS
    DataPlatform-Automation - Media Phase 1 Preparation and Validation Module
.DESCRIPTION
    Performs pre-flight preparation, validation, and structural verification of the 
    SQL Server media acquisition pipeline based on config/windows/mssql.conf.
    Ensures environmental readiness before actual download execution.
.NOTES
    Target OS: Windows Server 2019 / 2022
    PowerShell Version: 5.1+
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Define strict relative paths based on repository freeze structure
$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$ConfigPath = Join-Path $PROJECT_ROOT "config\windows\mssql.conf"
$DownloadDir = Join-Path $PROJECT_ROOT "databases\mssql\media"

Write-Output "[INIT] Starting SQL Server media pre-flight validation phase..."

# 1. Read and Parse Configuration File
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "[ERROR] Configuration file not found at expected path: $ConfigPath"
    exit 1
}

Write-Output "[CONFIG] Loading configurations from $ConfigPath"
$Config = @{}
# --- FIX (Issue 1): parsing wrapped in try/catch with line-number tracking.
#     Key/value split logic (`-match '='`, `-notmatch '^#'`, `-split '=', 2`, `.Trim()`)
#     is unchanged; only the iteration mechanism was changed from a pipeline to an
#     indexed loop so failures can be attributed to a specific line. ---
$LineNumber = 0
try {
    $ConfigLines = Get-Content -Path $ConfigPath
    foreach ($Line in $ConfigLines) {
        $LineNumber++
        if ($Line -match '=' -and $Line -notmatch '^#') {
            $Key, $Value = $Line -split '=', 2
            $Config[$Key.Trim()] = $Value.Trim()
        }
    }
}
catch {
    throw @"
[ERROR] [CONFIG] Failed to parse configuration file.

Configuration Path: $ConfigPath
Line Number: $LineNumber
Original Error: $($_.Exception.Message)
"@
}
# --- END FIX ---

# 2. Scalable Required Configuration Keys Validation
$RequiredKeys = @(
    "MSSQL_MEDIA_URL"
)

foreach ($Key in $RequiredKeys) {
    if (
        -not $Config.ContainsKey($Key) -or
        [string]::IsNullOrWhiteSpace($Config[$Key])
    ) {
        throw "[ERROR] Required configuration key missing or empty: $Key"
    }
}

$MediaUrl = $Config['MSSQL_MEDIA_URL']
Write-Output "[VALIDATION] Source Media URL found: $MediaUrl"

# 3. Media Directory Structural Validation
if (-not (Test-Path -Path $DownloadDir)) {
    Write-Output "[IO] Creating target media storage directory: $DownloadDir"
    $Null = New-Item -Path $DownloadDir -ItemType Directory -Force
} else {
    Write-Output "[IO] Verified target media storage directory exists: $DownloadDir"
}

# --- FIX (Issue 3): verify media directory is writable after creation/validation.
#     Directory creation logic above is unchanged; this is an additive check only. ---
Write-Output "[IO] Verifying write access to target media storage directory..."
try {
    $WritabilityProbePath = Join-Path $DownloadDir ".dpa_write_probe_$([guid]::NewGuid().ToString('N')).tmp"
    [System.IO.File]::WriteAllText($WritabilityProbePath, "write-check")
    Remove-Item -Path $WritabilityProbePath -Force -ErrorAction Stop
    Write-Output "[IO] Write access confirmed for: $DownloadDir"
}
catch {
    throw @"
[ERROR] [IO] Media storage directory is not writable.

Directory Path: $DownloadDir
Original Error: $($_.Exception.Message)
"@
}
# --- END FIX ---

# 4. URI Scheme and Source Format Structured Validation
Write-Output "[VALIDATION] Verifying source URI protocol format compliance..."

$IsValidSource = $false
# --- FIX (Issue 2): track and log the detected URI type without changing
#     validation behaviour. HTTP/HTTPS branch split for accurate type detection. ---
$DetectedUriType = "Unknown"

if ($MediaUrl.StartsWith("https://", [StringComparison]::OrdinalIgnoreCase)) {
    Write-Output "[VALIDATION] Valid enterprise web transport protocol detected (HTTP/HTTPS)."
    $DetectedUriType = "HTTPS"
    $IsValidSource = $true
}
elseif ($MediaUrl.StartsWith("http://", [StringComparison]::OrdinalIgnoreCase)) {
    Write-Output "[VALIDATION] Valid enterprise web transport protocol detected (HTTP/HTTPS)."
    $DetectedUriType = "HTTP"
    $IsValidSource = $true
}
elseif ($MediaUrl.StartsWith("\\")) {
    Write-Output "[VALIDATION] Valid enterprise network file system path detected (UNC Share)."
    $DetectedUriType = "UNC"
    $IsValidSource = $true
}
elseif ($MediaUrl -match '^[A-Za-z]:\\') {
    Write-Output "[VALIDATION] Valid absolute file system path structure detected."
    $DetectedUriType = "Local Path"
    $IsValidSource = $true
}

if (-not $IsValidSource) {
    throw "[ERROR] Unsupported or invalid URI scheme provided in MSSQL_MEDIA_URL. Source must match HTTP, HTTPS, UNC network share, or Local Absolute Path formats."
}

Write-Output "[VALIDATION] Detected URI Type: $DetectedUriType"
# --- END FIX ---

# 5. Extract and Validate Target Extension Metadata
$IsoFileName = [System.IO.Path]::GetFileName($MediaUrl.Split('?')[0])
if (-not [string]::IsNullOrEmpty($IsoFileName) -and -not ($IsoFileName.EndsWith(".iso", [StringComparison]::OrdinalIgnoreCase))) {
    # --- FIX (Issue 4): include original URL and parsed filename in the existing
    #     warning. Fallback behaviour (non-fatal Write-Output warning) unchanged. ---
    Write-Output "[WARNING] Parsed filename target metadata does not explicitly specify a standard .iso extension. Original URL: $MediaUrl | Parsed Filename: $IsoFileName"
    # --- END FIX ---
}

Write-Output ""
Write-Output "====================================="
Write-Output "MEDIA VALIDATION SUCCESSFUL"
Write-Output "====================================="
Write-Output "Source : $MediaUrl"
Write-Output "Media  : $DownloadDir"
Write-Output ""