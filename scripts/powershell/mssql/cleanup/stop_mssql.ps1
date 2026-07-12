$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "STOPPING MSSQL SERVER"
Write-Host "====================================="
Write-Host ""

# =====================================
# PROJECT ROOT
# =====================================

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path

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
# CHECK SERVICE
# =====================================

$Service = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

# =====================================
# IDEMPOTENCY
# =====================================

if (!$Service) {

    Write-Host "SQL Server service does not exist."
    Write-Host "Nothing to stop."
    Write-Host ""

    Write-Host "====================================="
    Write-Host "MSSQL STOP SUCCESSFUL"
    Write-Host "====================================="
    Write-Host ""

    exit 0
}

# =====================================
# STOP SERVICE
# =====================================

if ($Service.Status -eq "Stopped") {

    Write-Host "SQL Server service is already stopped."
}
else {

    Write-Host "Stopping SQL Server service..."
    Write-Host ""

    Stop-Service `
        -Name $ServiceName `
        -Force `
        -ErrorAction Stop

    $Timeout = 60
    $Elapsed = 0

    do {

        Start-Sleep -Seconds 2

        $Service = Get-Service `
            -Name $ServiceName `
            -ErrorAction SilentlyContinue

        $Elapsed += 2

    } until (
        $null -eq $Service -or
        $Service.Status -eq "Stopped" -or
        $Elapsed -ge $Timeout
    )

    if (
        $null -ne $Service -and
        $Service.Status -ne "Stopped"
    ) {
        throw "SQL Server service failed to stop within $Timeout seconds."
    }

    Write-Host "SQL Server service stopped successfully."
}

# =====================================
# FINAL VALIDATION
# =====================================

Write-Host ""
Write-Host "Validating MSSQL service status..."
Write-Host ""

$Service = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if (
    $null -ne $Service -and
    $Service.Status -ne "Stopped"
) {
    throw "MSSQL service validation failed. Service is still running."
}

Write-Host "MSSQL service validation passed."

Write-Host ""
Write-Host "====================================="
Write-Host "MSSQL STOP SUCCESSFUL"
Write-Host "====================================="
Write-Host ""

exit 0