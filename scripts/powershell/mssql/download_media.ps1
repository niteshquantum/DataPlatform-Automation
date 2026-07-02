<#
.SYNOPSIS
    DataPlatform-Automation - Realignment Media Acquisition Module
.DESCRIPTION
    Acquires SQL Server installation ISO based on enterprise parameters.
    Fully idempotent, headless, robust retry mechanics, and Jenkins/Terraform compatible.
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
$TrackingFile = Join-Path $DownloadDir "media_source.txt"

Write-Output "[INIT] Starting media acquisition engine..."

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

# Scalable validation block for required configuration keys
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

# 2. Extract Dynamic ISO Filename and Define Target Target Paths
$IsoFileName = [System.IO.Path]::GetFileName($MediaUrl.Split('?')[0])
if ([string]::IsNullOrEmpty($IsoFileName) -or -not ($IsoFileName.EndsWith(".iso", [StringComparison]::OrdinalIgnoreCase))) {
    Write-Output "[WARNING] Could not dynamically parse an ISO filename from URL. Defaulting target name."
    $IsoFileName = "SQLServerInstallationMedia.iso"
}

$TargetIsoPath = Join-Path $DownloadDir $IsoFileName
Write-Output "[CONFIG] Target local media path established: $TargetIsoPath"

# 3. Ensure Target Directories Exist
if (-not (Test-Path -Path $DownloadDir)) {
    Write-Output "[IO] Creating dedicated media folder at: $DownloadDir"
    $Null = New-Item -Path $DownloadDir -ItemType Directory -Force
}

# 4. Dynamic Cryptographic Protocol Negotiation (Adaptive TLS)
try {
    $AvailableProtocols = [Net.SecurityProtocolType]::Tls12
    if ([Net.SecurityProtocolType].GetEnumNames() -contains 'Tls13') {
        $AvailableProtocols = $AvailableProtocols -bor [Net.SecurityProtocolType]::Tls13
    }
    [Net.ServicePointManager]::SecurityProtocol = $AvailableProtocols
    Write-Output "[SECURITY] Crypto-capabilities locked to: $([Net.ServicePointManager]::SecurityProtocol)"
}
catch {
    Write-Output "[WARNING] Configuration of TLS 1.3 rejected by host OS. Defaulting securely to TLS 1.2 context."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# 5. Idempotency Validation Phase
# 5. Production Idempotency Validation
$ShouldDownload = $true

if (Test-Path $TargetIsoPath) {

    Write-Output "[IDEMPOTENCY] Existing SQL Server ISO detected."

    if ($Config.ContainsKey("MSSQL_MEDIA_SHA256") -and
        -not [string]::IsNullOrWhiteSpace($Config["MSSQL_MEDIA_SHA256"])) {

        $ExpectedHash = $Config["MSSQL_MEDIA_SHA256"].Trim()
        $ActualHash = (Get-FileHash $TargetIsoPath -Algorithm SHA256).Hash

        if ($ExpectedHash -ieq $ActualHash) {

            Write-Output "[SUCCESS] Existing ISO checksum verified."
            Set-Content -Path $TrackingFile -Value $MediaUrl -Force
            $ShouldDownload = $false

        }
        else {

            Write-Output "[WARNING] Existing ISO checksum mismatch."

            try {
                Remove-Item $TargetIsoPath -Force
                Write-Output "[CLEANUP] Corrupted ISO removed."
            }
            catch {
                throw "[ERROR] Existing ISO is locked. Unmount or close it before retrying."
            }

        }

    }
    else {

        Write-Output "[WARNING] No SHA256 configured. Existing ISO will be reused."
        Set-Content -Path $TrackingFile -Value $MediaUrl -Force
        $ShouldDownload = $false

    }

}

# 6. Execution and Enterprise Resilience Retry Block
if ($ShouldDownload) {
    if (Test-Path $TargetIsoPath) {
    Remove-Item $TargetIsoPath -Force
}
    $MaxRetries = 3
    $RetryCount = 0
    $DownloadSuccess = $false
    
    while (-not $DownloadSuccess -and $RetryCount -lt $MaxRetries) {
        try {
            $RetryCount++
            if ($MediaUrl.StartsWith("http://", [StringComparison]::OrdinalIgnoreCase) -or $MediaUrl.StartsWith("https://", [StringComparison]::OrdinalIgnoreCase)) {
                Write-Output "[NETWORK] Fetch execution via native web request stack (Attempt $RetryCount of $MaxRetries)..."
                
                Invoke-WebRequest -Uri $MediaUrl -OutFile $TargetIsoPath -UseBasicParsing
                if (-not (Test-Path $TargetIsoPath)) {
    throw "[ERROR] ISO download failed."
}
                $DownloadSuccess = $true
            }
            elseif ($MediaUrl.StartsWith("\\") -or (Test-Path -Path $MediaUrl -PathType Leaf)) {
                Write-Output "[SMB-FS] Executing direct storage platform block level mirror (Attempt $RetryCount of $MaxRetries)..."
                if (-not (Test-Path -Path $MediaUrl)) {
                    throw "Source network share file context path target unreachable or missing: $MediaUrl"
                }
                Copy-Item -Path $MediaUrl -Destination $TargetIsoPath -Force
                $DownloadSuccess = $true
            }
            else {
                Write-Error "[FATAL] Untrusted URI formatting layout structure parsed inside configuration targets."
                exit 1
            }
        }
        catch {
            Write-Output "[WARNING] Target transaction transmission failure on iteration ($RetryCount). Context: $_"
            if ($RetryCount -lt $MaxRetries) {
                $BackoffSeconds = [Math]::Pow(2, $RetryCount)
                Write-Output "[RETRY-ENGINE] Cooling pipeline. Backing off for $BackoffSeconds seconds before re-attempting transaction..."
                Start-Sleep -Seconds $BackoffSeconds
            } else {
                Write-Error "[FATAL] Network transmission thresholds breached. Maximum execution retry loop limit exhausted."
                exit 1
            }
        }
    }
    
    # Downloaded ISO Integrity Validation Check
    $DownloadedFile = Get-Item $TargetIsoPath
    if ($DownloadedFile.Length -lt 1MB) {
        throw "[ERROR] Downloaded installation media appears invalid or incomplete."
    }

    # Final post-download verification against configuration checksum if provided
    if ($Config.ContainsKey('MSSQL_MEDIA_SHA256') -and -not [string]::IsNullOrEmpty($Config['MSSQL_MEDIA_SHA256'])) {
        Write-Output "[CRYPTO] Evaluating downloaded media payload against configured SHA256 checksum..."
        $ExpectedHash = $Config['MSSQL_MEDIA_SHA256'].Trim()
        $ActualHash = (Get-FileHash -Path $TargetIsoPath -Algorithm SHA256).Hash
        if ($ExpectedHash -ine $ActualHash) {
            Write-Error "[FATAL] Checksum verification failed on downloaded file. Expected: $ExpectedHash, Got: $ActualHash"
            exit 1
        }
        Write-Output "[SUCCESS] Post-download checksum match confirmed."
    }

    # Store source tracking state mapping validation telemetry
    Set-Content -Path $TrackingFile -Value $MediaUrl -Force
}

# 7. Post-Flight Integrity Verification
if (-not (Test-Path -Path $TargetIsoPath)) {
    Write-Error "[VALIDATION] Target installation file missing post execution cycle at $TargetIsoPath"
    exit 1
}

$IsoSizeInBytes = (Get-Item -Path $TargetIsoPath).Length
Write-Output "[SUCCESS] Media Acquisition Stage Verification Clean. Output Destination: $TargetIsoPath ($IsoSizeInBytes bytes)"
exit 0