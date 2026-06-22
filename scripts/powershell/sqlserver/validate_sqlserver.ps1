# ============================================================
# validate_sqlserver.ps1
# SQL Server Full Validation
# Reuses Terraform W8 Verification Logic
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

$Global:ValidationPassed = $true

function Test-Check {
    param(
        [string]$Label,
        [bool]$Result
    )

    if ($Result) {
        Write-Host "  [PASS] $Label"
    }
    else {
        Write-Host "  [FAIL] $Label"
        $Global:ValidationPassed = $false
    }
}

try {

    # --------------------------------------------------------
    # Load Configuration
    # --------------------------------------------------------

    $ProjectRoot = Split-Path $PSScriptRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent
    $ProjectRoot = Split-Path $ProjectRoot -Parent

    $ConfigFile = Join-Path `
        $ProjectRoot `
        "config\sqlserver.conf"

    if (!(Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }

    $InstanceName = Get-ConfigValue `
        -FilePath $ConfigFile `
        -Key "INSTANCE_NAME"

    $DatabaseName = Get-ConfigValue `
        -FilePath $ConfigFile `
        -Key "DATABASE_NAME"

    $Port = Get-ConfigValue `
        -FilePath $ConfigFile `
        -Key "PORT"

    $SAPassword = Get-ConfigValue `
        -FilePath $ConfigFile `
        -Key "SA_PASSWORD"

    # --------------------------------------------------------
    # Setup
    # --------------------------------------------------------

    $ServiceName = if ($InstanceName -eq "MSSQLSERVER") {
        "MSSQLSERVER"
    }
    else {
        "MSSQL`$$InstanceName"
    }

    $Server = "localhost,$Port"

    $SqlCmd = Get-SqlCmdPath

    Write-Host ""
    Write-Host "================================================="
    Write-Host "     SQL SERVER FULL VALIDATION"
    Write-Host "================================================="
    Write-Host ""

    # --------------------------------------------------------
    # Service Validation
    # --------------------------------------------------------

    $Service = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if (-not $Service) {

    Write-Host ""
    Write-Host "Expected Instance : $InstanceName"
    Write-Host "Configured Port   : $Port"

    $Detected = Get-Service "MSSQL*" `
        -ErrorAction SilentlyContinue

    if ($Detected) {

        Write-Host ""
        Write-Host "Detected SQL Instances:"

        $Detected |
        Select Name, Status |
        Format-Table
    }
}

    Test-Check `
        "Service '$ServiceName' Running" `
        ($Service -and $Service.Status -eq "Running")

    # --------------------------------------------------------
    # sqlcmd Validation
    # --------------------------------------------------------

    Test-Check `
        "sqlcmd Available" `
        ($null -ne $SqlCmd)

    # --------------------------------------------------------
    # Windows Authentication
    # --------------------------------------------------------

    & $SqlCmd `
        -S "localhost" `
        -E `
        -Q "SELECT 1" `
        2>&1 | Out-Null

    Test-Check `
        "Windows Authentication Connectivity" `
        ($LASTEXITCODE -eq 0)

    # --------------------------------------------------------
    # SA Authentication
    # --------------------------------------------------------

    & $SqlCmd `
        -S $Server `
        -U SA `
        -P $SAPassword `
        -Q "SELECT 1" `
        2>&1 | Out-Null

    Test-Check `
        "SA Authentication Connectivity" `
        ($LASTEXITCODE -eq 0)

    # --------------------------------------------------------
    # Database Validation
    # --------------------------------------------------------

    $DatabaseResult = & $SqlCmd `
        -S "localhost" `
        -E `
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name='$DatabaseName'" `
        2>&1

    $DatabaseExists =
        (($DatabaseResult | Out-String) -match "[1-9]")

    Test-Check `
        "Database '$DatabaseName' Exists" `
        $DatabaseExists

    # --------------------------------------------------------
    # Table Validation
    # --------------------------------------------------------

    $RequiredTables = @(
        "Customers",
        "Products",
        "Orders"
    )

    foreach ($Table in $RequiredTables) {

        $TableResult = & $SqlCmd `
            -S $Server `
            -U SA `
            -P $SAPassword `
            -d $DatabaseName `
            -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='$Table'" `
            2>&1

        $TableExists =
            (($TableResult | Out-String) -match "[1-9]")

        Test-Check `
            "Table '$Table' Exists" `
            $TableExists
    }

    # --------------------------------------------------------
    # Seed Data Validation
    # --------------------------------------------------------

    $CustomerSeedResult = & $SqlCmd `
        -S $Server `
        -U SA `
        -P $SAPassword `
        -d $DatabaseName `
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.Customers" `
        2>&1

    $SeedExists =
        (($CustomerSeedResult | Out-String) -match "[1-9]")

    Test-Check `
        "Seed Data Exists (Customers)" `
        $SeedExists

    # --------------------------------------------------------
    # Join Validation
    # --------------------------------------------------------

    & $SqlCmd `
        -S "localhost" `
        -E `
        -d $DatabaseName `
        -Q "SELECT COUNT(*) FROM dbo.Orders o JOIN dbo.Customers c ON o.CustomerID = c.CustomerID" `
        2>&1 | Out-Null

    Test-Check `
        "Orders -> Customers Join Query" `
        ($LASTEXITCODE -eq 0)

    # --------------------------------------------------------
    # Summary
    # --------------------------------------------------------

    Write-Host ""

    if ($Global:ValidationPassed) {

        Write-Host "================================================="
        Write-Host "               ALL CHECKS PASSED"
        Write-Host "================================================="
        Write-Host "Instance : $InstanceName"
        Write-Host "Server   : $Server"
        Write-Host "Database : $DatabaseName"
        Write-Host "================================================="

        exit 0
    }
    else {

        Write-Host "================================================="
        Write-Host "             VALIDATION FAILED"
        Write-Host "================================================="

        exit 1
    }
}
catch {

    Write-Error $_.Exception.Message

    exit 1
}