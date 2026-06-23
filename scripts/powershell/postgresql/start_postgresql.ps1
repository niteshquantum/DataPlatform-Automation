$ErrorActionPreference = "Stop"

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
Write-Log "Port   : $Port"

if (!(Test-Path $PgCtl)) {
    throw "pg_ctl not found at: $PgCtl - run install step first"
}

$env:PATH = "$PgBin;$env:PATH"

$StatusOutput = & "$PgCtl" -D "$PgData" status 2>&1
Write-Log "Status: $StatusOutput"

if ($StatusOutput -match "server is running") {
    Write-Log "PostgreSQL already running - skipping start"
} else {
    Write-Log "Starting PostgreSQL..."
    & "$PgCtl" -D "$PgData" -l "$PgLog" start
    Start-Sleep -Seconds 5
}

Write-Log "Waiting for port $Port to be ready..."
$Ready = $false
for ($i = 1; $i -le $MaxRetries; $i++) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("localhost", $Port)
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
    throw "PostgreSQL not ready after $MaxRetries retries"
}

Write-Log "PostgreSQL started successfully"