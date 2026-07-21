$ErrorActionPreference = "Stop"

param (
    [ValidateSet("PRESERVE_DATA", "DELETE_DATA")]
    [string]$CleanupMode = "PRESERVE_DATA"
)

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

function Get-ProjectRoot {
    $Root = Split-Path $PSScriptRoot -Parent
    $Root = Split-Path $Root -Parent
    $Root = Split-Path $Root -Parent
    return $Root
}

$ProjectRoot = Get-ProjectRoot
$PgRoot = Join-Path $ProjectRoot "databases\postgresql"
$ConfigFile = Join-Path $ProjectRoot "config\windows\postgresql.conf"
$ServiceName = "PostgreSQLAutomation"

Write-Log "Searching PostgreSQL service"
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
$PortInUse = $false
if (Test-Path $ConfigFile) {
    $Config = @{}
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match "^([^#=]+)=(.*)$") {
            $Config[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    $Port = $Config["POSTGRESQL_PORT"]
    if ($Port) {
        $Listener = Get-NetTCPConnection -LocalPort ([int]$Port) -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Listener) {
            $PortInUse = $true
        }
    }
}

if ($Service -or $PortInUse) {
    Write-Log "Shared PostgreSQL instance is still in use."
    Write-Log "Preserving PostgreSQL deployment and data."
    exit 0
}

if (Test-Path $PgRoot) {
    if ($CleanupMode -eq "DELETE_DATA") {
        Remove-Item -Path $PgRoot -Recurse -Force
    }
    else {
        foreach ($Directory in @((Join-Path $PgRoot "bin"), (Join-Path $PgRoot "lib"), (Join-Path $PgRoot "share"))) {
            if (Test-Path $Directory) {
                Remove-Item -Path $Directory -Recurse -Force
            }
        }
    }
}

Write-Log "PostgreSQL removal process completed"