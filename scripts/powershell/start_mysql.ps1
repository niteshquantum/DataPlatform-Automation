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

Start-Process -FilePath "$baseDir\bin\mysqld.exe" -ArgumentList "--port=$port --basedir=$baseDir --datadir=$dataDir"

$Started = $false

for ($i = 1; $i -le 30; $i++) {


    $PortCheck = netstat -ano | Select-String ":$port"

    if ($PortCheck) {

        $Started = $true
        break
    }

    Start-Sleep -Seconds 1


}

if (-not $Started) {


    throw "MySQL failed to start on port $port"


}

Write-Host ""
Write-Host "====================================="
Write-Host "MySQL Started Successfully"
Write-Host "Port : $port"
Write-Host "====================================="
