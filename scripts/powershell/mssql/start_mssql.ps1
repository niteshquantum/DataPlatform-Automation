$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "STARTING MSSQL SERVER"
Write-Host "====================================="
Write-Host ""

$ServiceName = "MSSQLSERVER"

$Port = 1433

$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($null -eq $Service) {

    throw "SQL Server service '$ServiceName' not found."

}

if ($Service.Status -ne "Running") {

    Write-Host "Starting SQL Server Service..."

    Start-Service $ServiceName

    $Service.WaitForStatus("Running","00:00:30")

}

$Started = $false

for ($i=1; $i -le 30; $i++) {

    $PortCheck = netstat -ano | Select-String ":$Port"

    if ($PortCheck) {

        $Started = $true
        break

    }

    Start-Sleep -Seconds 1

}

if (-not $Started) {

    throw "SQL Server failed to start on port $Port"

}

Write-Host ""
Write-Host "====================================="
Write-Host "SQL SERVER STARTED SUCCESSFULLY"
Write-Host "Service : $ServiceName"
Write-Host "Port    : $Port"
Write-Host "====================================="
Write-Host ""

exit 0