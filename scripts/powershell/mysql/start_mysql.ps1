$ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$configFile = "$ROOT\config\windows\mysql.conf"

if (!(Test-Path $configFile)) {
    throw "Config file not found: $configFile"
}

$port = (
    Get-Content $configFile |
    Where-Object { $_ -match "^MYSQL_PORT=" } |
    ForEach-Object { ($_ -split "=")[1].Trim() }
)

$baseDir = "$ROOT\databases\mysql\server"
$dataDir = "$ROOT\databases\mysql\data"
$mysqld  = "$baseDir\bin\mysqld.exe"
$mysqladmin = "$baseDir\bin\mysqladmin.exe"
$mysqlHost = "127.0.0.1"

Write-Host ""
Write-Host "====================================="
Write-Host "STARTING MYSQL"
Write-Host "====================================="
Write-Host "BaseDir : $baseDir"
Write-Host "DataDir : $dataDir"
Write-Host "Port    : $port"
Write-Host ""

if (!(Test-Path $mysqld)) {
    throw "mysqld.exe not found: $mysqld"
}

if (!(Test-Path $mysqladmin)) {
    throw "mysqladmin.exe not found: $mysqladmin"
}

if (!(Test-Path $dataDir)) {
    throw "Data directory not found: $dataDir"
}

$portListener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1

if ($portListener) {
    Write-Host "MySQL is already listening on port $port. Reusing the existing instance."

    try {
        & $mysqladmin --host=$mysqlHost --port=$port -u root ping 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Existing MySQL instance is responsive."
            exit 0
        }
    }
    catch {
    }

    Write-Host "The existing instance is present but not yet responsive. Leaving it in place and continuing."
    exit 0
}

$env:JENKINS_NODE_COOKIE = "MySQLAutomationProcess"
Start-Process `
    -FilePath $mysqld `
    -ArgumentList @(
        "--port=$port",
        "--basedir=$baseDir",
        "--datadir=$dataDir"
    ) `
    -WindowStyle Hidden

$started = $false

for ($i = 1; $i -le 60; $i++) {

    try {
        & $mysqladmin --host=$mysqlHost --port=$port -u root ping 2>$null | Out-Null

        if ($LASTEXITCODE -eq 0) {
            $started = $true
            break
        }
    }
    catch {
    }

    Start-Sleep -Seconds 1
}

if (-not $started) {
    Write-Host ""
    Write-Host "MySQL error log:"
    Write-Host "-------------------------------------"

    Get-ChildItem $dataDir -Filter "*.err" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    ForEach-Object {
        Get-Content $_.FullName -Tail 30
    }

    throw "MySQL failed to start on port $port"
}

Write-Host ""
Write-Host "====================================="
Write-Host "MYSQL START SUCCESSFUL"
Write-Host "Port : $port"
Write-Host "====================================="
Write-Host ""

