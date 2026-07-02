



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
Get-Content -Path $ConfigPath | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $Key, $Value = $_ -split '=', 2
    $Config[$Key.Trim()] = $Value.Trim()
}

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

# 4. URI Scheme and Source Format Structured Validation
Write-Output "[VALIDATION] Verifying source URI protocol format compliance..."

$IsValidSource = $false

if ($MediaUrl.StartsWith("http://", [StringComparison]::OrdinalIgnoreCase) -or $MediaUrl.StartsWith("https://", [StringComparison]::OrdinalIgnoreCase)) {
    Write-Output "[VALIDATION] Valid enterprise web transport protocol detected (HTTP/HTTPS)."
    $IsValidSource = $true
}
elseif ($MediaUrl.StartsWith("\\")) {
    Write-Output "[VALIDATION] Valid enterprise network file system path detected (UNC Share)."
    $IsValidSource = $true
}
elseif ($MediaUrl -match '^[A-Za-z]:\\') {
    Write-Output "[VALIDATION] Valid absolute file system path structure detected."
    $IsValidSource = $true
}

if (-not $IsValidSource) {
    throw "[ERROR] Unsupported or invalid URI scheme provided in MSSQL_MEDIA_URL. Source must match HTTP, HTTPS, UNC network share, or Local Absolute Path formats."
}

# 5. Extract and Validate Target Extension Metadata
$IsoFileName = [System.IO.Path]::GetFileName($MediaUrl.Split('?')[0])
if (-not [string]::IsNullOrEmpty($IsoFileName) -and -not ($IsoFileName.EndsWith(".iso", [StringComparison]::OrdinalIgnoreCase))) {
    Write-Output "[WARNING] Parsed filename target metadata does not explicitly specify a standard .iso extension."
}

Write-Output ""
Write-Output "====================================="
Write-Output "MEDIA VALIDATION SUCCESSFUL"
Write-Output "====================================="
Write-Output "Source : $MediaUrl"
Write-Output "Media  : $DownloadDir"
Write-Output ""