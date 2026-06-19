# ============================================================
# create_database.ps1
# Create SQL Server Database
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

    Write-Log "Starting database creation process"

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
        "sql\create_database.sql"

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
    # Execute create_database.sql
    # --------------------------------------------------------

    Write-Log "Executing create_database.sql"

    & $SqlCmd `
        -S $Server `
        -U SA `
        -P $SAPassword `
        -i $SqlFile `
        -v DB_NAME=$DatabaseName

    if ($LASTEXITCODE -ne 0) {
        throw "create_database.sql execution failed"
    }

    Write-Log "Database creation script executed successfully"

    # --------------------------------------------------------
    # Validate Database Exists
    # --------------------------------------------------------

    Write-Log "Validating database existence"

    $Result = & $SqlCmd `
        -S $Server `
        -U SA `
        -P $SAPassword `
        -h -1 `
        -W `
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name='$DatabaseName'"

    if ($LASTEXITCODE -ne 0) {
        throw "Database validation query failed"
    }

    $DatabaseCount = (
        ($Result | Out-String).Trim()
    )

    if ([int]$DatabaseCount -lt 1) {
        throw "Database validation failed: $DatabaseName not found"
    }

    Write-Log "Database validated successfully"

    Write-Log "Database creation completed"

    exit 0
}
catch {

    Write-Error $_.Exception.Message

    exit 1
}