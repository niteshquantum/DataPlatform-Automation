# ============================================================
# create_tables.ps1
# Create SQL Server Tables
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

function Get-ConfigValue {
    param(
        [string]$FilePath,
        [string]$Key
    )

    $Line = Get-Content $FilePath |
            Where-Object { $_ -match "^$Key=" } |
            Select-Object -First 1

    if (-not $Line) {
        throw "Configuration key not found: $Key"
    }

    return ($Line -split "=",2)[1].Trim()
}

function Get-SqlCmdPath {

    if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
        return (Get-Command sqlcmd).Source
    }

    $SqlCmd = Get-ChildItem `
        "C:\Program Files\Microsoft SQL Server" `
        -Recurse `
        -Filter "sqlcmd.exe" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $SqlCmd) {
        throw "sqlcmd.exe not found"
    }

    return $SqlCmd.FullName
}

try {

    Write-Log "Starting table creation process"

    # --------------------------------------------------------
    # Project Paths
    # --------------------------------------------------------

    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent

    $ConfigFile = Join-Path $ProjectRoot "config\sqlserver.conf"

    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }

    # --------------------------------------------------------
    # Load Configuration
    # --------------------------------------------------------

    $DatabaseName = Get-ConfigValue `
        -FilePath $ConfigFile `
        -Key "DATABASE_NAME"

    $Port = Get-ConfigValue `
        -FilePath $ConfigFile `
        -Key "PORT"

    $SAPassword = Get-ConfigValue `
        -FilePath $ConfigFile `
        -Key "SA_PASSWORD"

    $SqlFile = Join-Path `
        $ProjectRoot `
        "sql\create_tables.sql"

    if (!(Test-Path $SqlFile)) {
        throw "SQL file not found: $SqlFile"
    }

    # --------------------------------------------------------
    # Discover sqlcmd
    # --------------------------------------------------------

    $SqlCmd = Get-SqlCmdPath

    Write-Log "sqlcmd located: $SqlCmd"

    $Server = "localhost,$Port"

    # --------------------------------------------------------
    # Execute create_tables.sql
    # --------------------------------------------------------

    Write-Log "Executing create_tables.sql"

    & $SqlCmd `
        -S $Server `
        -U SA `
        -P $SAPassword `
        -d $DatabaseName `
        -i $SqlFile

    if ($LASTEXITCODE -ne 0) {
        throw "create_tables.sql execution failed"
    }

    Write-Log "Table creation script executed successfully"

    # --------------------------------------------------------
    # Validate Tables Exist
    # --------------------------------------------------------

    Write-Log "Validating required tables"

    $RequiredTables = @(
        "Customers",
        "Products",
        "Orders"
    )

    foreach ($Table in $RequiredTables) {

        $Result = & $SqlCmd `
            -S $Server `
            -U SA `
            -P $SAPassword `
            -d $DatabaseName `
            -h -1 `
            -W `
            -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='$Table'"

        if ($LASTEXITCODE -ne 0) {
            throw "Validation query failed for table: $Table"
        }

        $TableCount = (
            ($Result | Out-String).Trim()
        )

        if ([int]$TableCount -lt 1) {
            throw "Required table missing: $Table"
        }

        Write-Log "Validated table: $Table"
    }

    # --------------------------------------------------------
    # Validate Base Table Count
    # --------------------------------------------------------

    $TableResult = & $SqlCmd `
        -S $Server `
        -U SA `
        -P $SAPassword `
        -d $DatabaseName `
        -h -1 `
        -W `
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to validate table count"
    }

    $TotalTables = [int](($TableResult | Out-String).Trim())

    if ($TotalTables -lt 3) {
        throw "Unexpected table count detected: $TotalTables"
    }

    Write-Log "Total tables found: $TotalTables"

    Write-Log "Table validation completed successfully"

    exit 0
}
catch {

    Write-Error $_.Exception.Message

    exit 1
}