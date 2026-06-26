$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
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

if ($Config["POSTGRESQL_PORT"]) { $Port = [int]$Config["POSTGRESQL_PORT"] } else { $Port = 5432 }
$MaxRetries    = 30
$RetryInterval = 3

$PgBin  = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgData = Join-Path $ProjectRoot "databases\postgresql\data"
$PgLog  = Join-Path $ProjectRoot "databases\postgresql\pg_server.log"
$PgCtl  = Join-Path $PgBin "pg_ctl.exe"

Write-Log "pg_ctl : $PgCtl"
Write-Log "Data   : $PgData"
Write-Log "Log    : $PgLog"
Write-Log "Port   : $Port"

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl not found at: $PgCtl - run install step first"
}

$env:PATH = "$PgBin;$env:PATH"

# FIX: Delete stale postmaster.opts so pg_ctl does not use old D:/QT path
$PostmasterOpts = Join-Path $PgData "postmaster.opts"
if (Test-Path $PostmasterOpts) {
    $OptsContent = Get-Content $PostmasterOpts -Raw
    if ($OptsContent -notmatch [regex]::Escape($ProjectRoot)) {
        Write-Log "Removing stale postmaster.opts (wrong path detected): $OptsContent"
        Remove-Item $PostmasterOpts -Force
    }
}

# FIX: Delete postmaster.pid if server is NOT actually running (stale lock)
$PostmasterPid = Join-Path $PgData "postmaster.pid"
if (Test-Path $PostmasterPid) {
    $PidContent = Get-Content $PostmasterPid
    $StoredPid  = [int]($PidContent[0].Trim())
    $ProcRunning = Get-Process -Id $StoredPid -ErrorAction SilentlyContinue
    if (-not $ProcRunning) {
        Write-Log "Removing stale postmaster.pid (PID $StoredPid not running)"
        Remove-Item $PostmasterPid -Force
    }
}

$StatusOutput = & "$PgCtl" -D "$PgData" status 2>&1
Write-Log "Status: $StatusOutput"



Write-Log "Waiting for port $Port to be ready..."
$Ready = $false
if (($StatusOutput -join " ") -match "server is running") {
    Write-Log "PostgreSQL already running - stopping first for clean start..."
    & "$PgCtl" -D "$PgData" stop -m fast 2>&1 | Out-Null
    Start-Sleep -Seconds 3
}

Write-Log "Starting PostgreSQL..."
$StartOutput = & "$PgCtl" -D "$PgData" -l "$PgLog" start -w 2>&1
Write-Log "pg_ctl output: $StartOutput"

Write-Log "Waiting for port $Port to be ready..."
$Ready = $false
for ($i = 1; $i -le $MaxRetries; $i++) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("127.0.0.1", $Port)
        $tcp.Close()
        $Ready = $true
        Write-Log "PostgreSQL ready on port $Port (attempt $i)"
        break
    } catch {
        Write-Log "Waiting... $i/$MaxRetries"
        Start-Sleep -Seconds $RetryInterval
    }
}

if (!$Ready) {
    Write-Log "Last 20 lines of server log:"
    if (Test-Path $PgLog) { Get-Content $PgLog -Tail 20 | ForEach-Object { Write-Log $_ } }
    throw "PostgreSQL not ready after $MaxRetries retries"
}

Write-Log "PostgreSQL started successfully"