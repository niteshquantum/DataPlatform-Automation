$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)

    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

$Service = Get-Service |
Where-Object {
    $_.Name -match "postgres"
} |
Select-Object -First 1

if (!$Service) {

    throw "PostgreSQL service not found"
}

if ($Service.Status -eq "Stopped") {

    Write-Log "Service already stopped"

    exit 0
}

Stop-Service `
    -Name $Service.Name `
    -Force

Start-Sleep 5

$Service.Refresh()

if ($Service.Status -ne "Stopped") {

    throw "Failed to stop PostgreSQL"
}

Write-Log "PostgreSQL stopped successfully"