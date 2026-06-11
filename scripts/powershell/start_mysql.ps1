$ROOT = (Resolve-Path "$PSScriptRoot\..\..").Path

$configFile = "$ROOT\config\mysql.conf"

$port = (
    Get-Content $configFile |
    Where-Object { $_ -match "^MYSQL_PORT=" } |
    ForEach-Object { ($_ -split "=")[1].Trim() }
)

$baseDir = "$ROOT\databases\mysql\server"
$dataDir = "$ROOT\databases\mysql\data"

if (!(Test-Path "$baseDir\bin\mysqld.exe")) {

    throw "mysqld.exe not found. Run deploy_mysql.bat first."
}

Start-Process `
    -FilePath "$baseDir\bin\mysqld.exe" `
    -ArgumentList "--port=$port --basedir=$baseDir --datadir=$dataDir"

Start-Sleep -Seconds 10

Write-Host ""
Write-Host "====================================="
Write-Host "MySQL Started Successfully"
Write-Host "Port : $port"
Write-Host "====================================="