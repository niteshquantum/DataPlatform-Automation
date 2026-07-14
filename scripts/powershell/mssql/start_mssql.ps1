$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "STARTING MSSQL SERVER"
Write-Host "====================================="
Write-Host ""

# =====================================
# PROJECT ROOT
# =====================================

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

# =====================================
# LOAD CONFIG
# =====================================

. "$PROJECT_ROOT\scripts\powershell\common\load_config.ps1"

$Config = Load-Config "$PROJECT_ROOT\config\windows\mssql.conf"

$Instance = $Config["MSSQL_INSTANCE"]

if ([string]::IsNullOrWhiteSpace($Instance)) {
    throw "MSSQL_INSTANCE is missing in config/windows/mssql.conf"
}

# =====================================
# SERVICE NAME
# =====================================

if ($Instance -eq "MSSQLSERVER") {
    $ServiceName = "MSSQLSERVER"
}
else {
    $ServiceName = "MSSQL`$$Instance"
}

Write-Host "Instance     : $Instance"
Write-Host "Service Name : $ServiceName"
Write-Host ""

# =====================================
# VERIFY SERVICE EXISTS
# =====================================

$Service = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if (!$Service) {

    throw "SQL Server service '$ServiceName' was not found."

}

# =====================================
# START SERVICE
# =====================================

if ($Service.Status -eq "Running") {

    Write-Host "[OK] SQL Server service is already running."

}
else {

    Write-Host "Starting SQL Server service..."
    Write-Host ""

    Start-Service -Name $ServiceName

    $Timeout = 60
    $Elapsed = 0

    do {

        Start-Sleep -Seconds 2

        $Service = Get-Service -Name $ServiceName

        $Elapsed += 2

    } until (
        $Service.Status -eq "Running" -or
        $Elapsed -ge $Timeout
    )

    if ($Service.Status -ne "Running") {

        throw "SQL Server service failed to start within $Timeout seconds."

    }

    Write-Host "[OK] SQL Server service started successfully."

}

# =====================================
# FINAL STATUS
# =====================================

$Service = Get-Service -Name $ServiceName

Write-Host ""
Write-Host "====================================="
Write-Host "MSSQL SERVER STATUS"
Write-Host "====================================="
Write-Host ""

Write-Host ("Service Name : {0}" -f $Service.Name)
Write-Host ("Status       : {0}" -f $Service.Status)
Write-Host ("Start Type   : {0}" -f $Service.StartType)

Write-Host ""
Write-Host "[SUCCESS] MSSQL Server is running."
Write-Host ""

exit 0