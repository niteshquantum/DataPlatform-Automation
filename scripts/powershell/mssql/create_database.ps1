$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "CREATE DATABASE"
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

$Server   = $Config["MSSQL_HOST"]
$Port     = $Config["MSSQL_PORT"]
$Database = $Config["MSSQL_DB"]
$User     = $Config["MSSQL_USER"]
$Password = $Config["MSSQL_PASSWORD"]

# =====================================
# VALIDATE CONFIG
# =====================================

if ([string]::IsNullOrWhiteSpace($Server)) {
    throw "MSSQL_HOST is not configured."
}

if ([string]::IsNullOrWhiteSpace($Port)) {
    throw "MSSQL_PORT is not configured."
}

if ([string]::IsNullOrWhiteSpace($Database)) {
    throw "MSSQL_DB is not configured."
}

if ([string]::IsNullOrWhiteSpace($User)) {
    throw "MSSQL_USER is not configured."
}

Write-Host "Host     : $Server"
Write-Host "Port     : $Port"
Write-Host "Database : $Database"
Write-Host "User     : $User"
Write-Host ""

# =====================================
# VALIDATE SQLCMD
# =====================================

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue

if (!$sqlcmd) {
    throw "sqlcmd utility not found in PATH."
}

# =====================================
# CHECK DATABASE
# =====================================

Write-Host "Checking database..."
Write-Host ""

$dbExists = sqlcmd `
    -S "$Server,$Port" `
    -U $User `
    -P $Password `
    -d master `
    -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '$Database';" `
    -h -1 `
    -W

if ($LASTEXITCODE -ne 0) {
    throw "Unable to query SQL Server."
}

if ($dbExists.Trim() -eq "1") {

    Write-Host "[OK] Database '$Database' already exists."

    Write-Host ""
    Write-Host "====================================="
    Write-Host "DATABASE READY"
    Write-Host "====================================="
    Write-Host ""

    exit 0
}

# =====================================
# CREATE DATABASE
# =====================================

Write-Host "Creating database..."
Write-Host ""

sqlcmd `
    -S "$Server,$Port" `
    -U $User `
    -P $Password `
    -d master `
    -Q "CREATE DATABASE [$Database];"

if ($LASTEXITCODE -ne 0) {
    throw "Database creation failed."
}

Write-Host "[OK] Database created."

# =====================================
# VERIFY DATABASE
# =====================================

$dbExists = sqlcmd `
    -S "$Server,$Port" `
    -U $User `
    -P $Password `
    -d master `
    -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '$Database';" `
    -h -1 `
    -W

if ($LASTEXITCODE -ne 0) {
    throw "Unable to verify database."
}

if ($dbExists.Trim() -ne "1") {
    throw "Database verification failed."
}

Write-Host "[OK] Database verified."

# =====================================
# SUCCESS
# =====================================

Write-Host ""
Write-Host "====================================="
Write-Host "DATABASE READY"
Write-Host "====================================="
Write-Host ""

Write-Host "Host     : $Server"
Write-Host "Port     : $Port"
Write-Host "Database : $Database"

Write-Host ""
Write-Host "[SUCCESS] Database creation completed successfully."
Write-Host ""

exit 0