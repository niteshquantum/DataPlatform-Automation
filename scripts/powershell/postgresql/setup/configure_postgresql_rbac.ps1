$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "CONFIGURING POSTGRESQL RBAC"
Write-Host "====================================="
Write-Host ""

# ----------------------------------------------------------
# PROJECT ROOT
# ----------------------------------------------------------

$ROOT = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
$ConfigFile = "$ROOT\config\windows\postgresql.conf"

if (!(Test-Path $ConfigFile)) {
    throw "Config file not found: $ConfigFile"
}

# ----------------------------------------------------------
# READ CONFIG
# ----------------------------------------------------------

$Config = @{}

Get-Content $ConfigFile | ForEach-Object {

    $Line = $_.Trim()

    if (
        $Line -and
        -not $Line.StartsWith("#") -and
        $Line.Contains("=")
    ) {
        $Key, $Value = $Line.Split("=",2)
        $Config[$Key.Trim()] = $Value.Trim()
    }
}

$PgHost     = $Config["POSTGRESQL_HOST"]
$PgPort     = $Config["POSTGRESQL_PORT"]
$PgDatabase = $Config["POSTGRESQL_DB"]
$PgPassword = $Config["POSTGRESQL_PASSWORD"]

$AdminUser      = $Config["RBAC_ADMIN_USERNAME"]
$AdminPassword  = $Config["RBAC_ADMIN_PASSWORD"]

$DeveloperUser     = $Config["RBAC_DEVELOPER_USERNAME"]
$DeveloperPassword = $Config["RBAC_DEVELOPER_PASSWORD"]

$QaUser     = $Config["RBAC_QA_USERNAME"]
$QaPassword = $Config["RBAC_QA_PASSWORD"]

$ViewerUser     = $Config["RBAC_VIEWER_USERNAME"]
$ViewerPassword = $Config["RBAC_VIEWER_PASSWORD"]

# ----------------------------------------------------------
# RESOLVE PSQL
# ----------------------------------------------------------

$WorkspacePsqlExe = Join-Path $ROOT "databases\postgresql\bin\psql.exe"

if (Test-Path $WorkspacePsqlExe) {

    $PsqlExe = (Resolve-Path $WorkspacePsqlExe).Path

}
else {

    throw "psql.exe not found."
}

Write-Host "psql.exe : $PsqlExe"
Write-Host ""

$env:PGPASSWORD = $PgPassword

# ----------------------------------------------------------
# HELPER
# ----------------------------------------------------------

function Execute-Sql {

    param([string]$Sql)

    & $PsqlExe `
        --host="$PgHost" `
        --port="$PgPort" `
        --username=postgres `
        --dbname="$PgDatabase" `
        --command="$Sql" `
        2>&1 | Out-Null
}

function Ensure-Role {

    param([string]$RoleName)

    $Exists = & $PsqlExe `
        --host="$PgHost" `
        --port="$PgPort" `
        --username=postgres `
        --dbname=postgres `
        --tuples-only `
        --command="SELECT COUNT(*) FROM pg_roles WHERE rolname='$RoleName';"

    $Exists = ($Exists -replace '[^\d]','')

    if ([int]$Exists -eq 0) {

        Write-Host "Creating role $RoleName"

        Execute-Sql "CREATE ROLE $RoleName NOLOGIN;"

    }
    else {

        Write-Host "Role $RoleName already exists."

    }
}

function Ensure-User {

    param(
        [string]$UserName,
        [string]$Password
    )

    $Exists = & $PsqlExe `
        --host="$PgHost" `
        --port="$PgPort" `
        --username=postgres `
        --dbname=postgres `
        --tuples-only `
        --command="SELECT COUNT(*) FROM pg_roles WHERE rolname='$UserName';"

    $Exists = ($Exists -replace '[^\d]','')

    if ([int]$Exists -eq 0) {

        Write-Host "Creating user $UserName"

        Execute-Sql "CREATE USER ""$UserName"" WITH PASSWORD '$Password';"

    }
    else {

        Write-Host "Updating password for $UserName"

        Execute-Sql "ALTER USER ""$UserName"" WITH PASSWORD '$Password';"

    }
}

# ----------------------------------------------------------
# CREATE ROLES
# ----------------------------------------------------------

Ensure-Role "dp_admin"
Ensure-Role "dp_developer"
Ensure-Role "dp_qa"
Ensure-Role "dp_viewer"

# ----------------------------------------------------------
# CREATE USERS
# ----------------------------------------------------------

Ensure-User $AdminUser $AdminPassword
Ensure-User $DeveloperUser $DeveloperPassword
Ensure-User $QaUser $QaPassword
Ensure-User $ViewerUser $ViewerPassword

# ----------------------------------------------------------
# ROLE MEMBERSHIP
# ----------------------------------------------------------

Execute-Sql "GRANT dp_admin TO ""$AdminUser"";"
Execute-Sql "GRANT dp_developer TO ""$DeveloperUser"";"
Execute-Sql "GRANT dp_qa TO ""$QaUser"";"
Execute-Sql "GRANT dp_viewer TO ""$ViewerUser"";"

# ----------------------------------------------------------
# DATABASE ACCESS
# ----------------------------------------------------------

Execute-Sql "GRANT CONNECT ON DATABASE ""$PgDatabase"" TO dp_admin;"
Execute-Sql "GRANT CONNECT ON DATABASE ""$PgDatabase"" TO dp_developer;"
Execute-Sql "GRANT CONNECT ON DATABASE ""$PgDatabase"" TO dp_qa;"
Execute-Sql "GRANT CONNECT ON DATABASE ""$PgDatabase"" TO dp_viewer;"

# ----------------------------------------------------------
# SCHEMA ACCESS
# ----------------------------------------------------------

Execute-Sql "GRANT USAGE,CREATE ON SCHEMA public TO dp_admin;"
Execute-Sql "GRANT USAGE,CREATE ON SCHEMA public TO dp_developer;"
Execute-Sql "GRANT USAGE ON SCHEMA public TO dp_qa;"
Execute-Sql "GRANT USAGE ON SCHEMA public TO dp_viewer;"

# ----------------------------------------------------------
# TABLE PRIVILEGES
# ----------------------------------------------------------

Execute-Sql "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dp_admin;"
Execute-Sql "GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO dp_developer;"
Execute-Sql "GRANT SELECT ON ALL TABLES IN SCHEMA public TO dp_qa;"
Execute-Sql "GRANT SELECT ON ALL TABLES IN SCHEMA public TO dp_viewer;"

# ----------------------------------------------------------
# SEQUENCE PRIVILEGES
# ----------------------------------------------------------

Execute-Sql "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dp_admin;"
Execute-Sql "GRANT USAGE,SELECT,UPDATE ON ALL SEQUENCES IN SCHEMA public TO dp_developer;"
Execute-Sql "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO dp_qa;"
Execute-Sql "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO dp_viewer;"

# ----------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------

Execute-Sql "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO dp_admin;"
Execute-Sql "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO dp_developer;"
Execute-Sql "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO dp_qa;"
Execute-Sql "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO dp_viewer;"

# ----------------------------------------------------------
# DEFAULT PRIVILEGES
# ----------------------------------------------------------

Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO dp_admin;"
Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO dp_developer;"
Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dp_qa;"
Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dp_viewer;"

Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO dp_admin;"
Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE,SELECT,UPDATE ON SEQUENCES TO dp_developer;"
Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO dp_qa;"
Execute-Sql "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO dp_viewer;"

# ----------------------------------------------------------
# CLEANUP
# ----------------------------------------------------------

$env:PGPASSWORD = $null

Write-Host ""
Write-Host "====================================="
Write-Host "POSTGRESQL RBAC CONFIGURED SUCCESSFULLY"
Write-Host "====================================="
Write-Host ""

exit 0