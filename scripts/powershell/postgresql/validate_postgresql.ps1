$ErrorActionPreference = "SilentlyContinue"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

function Write-Report {
    param([string]$Label, [string]$Expected, [string]$Detected, [bool]$Pass = $true)
    $Status = if ($Pass) { "OK" } else { "WARN" }
    Write-Host ""
    Write-Host "  $Label"
    Write-Host "    Expected : $Expected"
    Write-Host "    Detected : $Detected   [$Status]"
}

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

$ConfigFile = Join-Path $ProjectRoot "config\postgresql.conf"
$Config = @{}
if (Test-Path $ConfigFile) {
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match "^([^#=]+)=(.*)$") {
            $Config[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
}

$ExpectedDatabase = $Config["POSTGRESQL_DATABASE"]
$ExpectedPort     = $Config["POSTGRESQL_PORT"]
$ExpectedUser     = $Config["POSTGRESQL_ADMIN_USER"]

# Use project folder psql — not system PATH
$PgBin   = Join-Path $ProjectRoot "databases\postgresql\bin"
$PsqlExe = Join-Path $PgBin "psql.exe"
$env:PATH = "$PgBin;$env:PATH"

Write-Host ""
Write-Host "========================================================"
Write-Host "POSTGRESQL VALIDATION REPORT"
Write-Host "========================================================"

# --- Port check ---
$PortInUse = $false
try {
    $conn = New-Object System.Net.Sockets.TcpClient
    $conn.Connect("localhost", [int]$ExpectedPort)
    $PortInUse = $true
    $conn.Close()
} catch {}
$DetectedPort = if ($PortInUse) { "$ExpectedPort (OPEN)" } else { "$ExpectedPort (CLOSED)" }
Write-Report "PORT" "$ExpectedPort (OPEN)" $DetectedPort $PortInUse

# --- psql available ---
$PsqlAvailable = Test-Path $PsqlExe
Write-Report "PSQL BINARY" "$PsqlExe" $(if ($PsqlAvailable) { "FOUND" } else { "MISSING" }) $PsqlAvailable

if ($PsqlAvailable) {
    $Version = (& "$PsqlExe" "--version" 2>&1)
    Write-Report "VERSION" "PostgreSQL" $Version $true
}

# --- Database exists ---
$DBExists = $false
if ($PsqlAvailable -and $PortInUse) {
    $DBResult = & "$PsqlExe" -U $ExpectedUser -h localhost -p $ExpectedPort -t -c "SELECT COUNT(*) FROM pg_database WHERE datname='$ExpectedDatabase';" 2>&1
    $DBExists = ($DBResult -match "1")
    $DetectedDB = if ($DBExists) { "$ExpectedDatabase (EXISTS)" } else { "$ExpectedDatabase (NOT FOUND)" }
    Write-Report "DATABASE" "$ExpectedDatabase (EXISTS)" $DetectedDB $DBExists
}

# --- Tables and row counts ---
$EXPECTED_TABLES = @("customers","products","orders","sellers","orderdetails")
Write-Host ""
Write-Host "  TABLES + ROW COUNTS"

if ($PsqlAvailable -and $DBExists) {
    foreach ($Table in $EXPECTED_TABLES) {
        $CResult = & "$PsqlExe" -U $ExpectedUser -h localhost -p $ExpectedPort -d $ExpectedDatabase -t -c "SELECT COUNT(*) FROM $Table;" 2>&1
        $Count = ($CResult -replace '\s','').Trim()
        $Status = if ($Count -gt 0) { "OK" } else { "EMPTY" }
        Write-Host "    $($Table.PadRight(20)) $($Count.PadRight(8)) [$Status]"
    }
}

Write-Host ""
Write-Host "========================================================"
Write-Host "Validation completed"
Write-Host "========================================================"