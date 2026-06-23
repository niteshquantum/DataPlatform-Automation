$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

function Get-ProjectRoot {
    $Root = Split-Path $PSScriptRoot -Parent
    $Root = Split-Path $Root -Parent
    $Root = Split-Path $Root -Parent
    return $Root
}

$ProjectRoot     = Get-ProjectRoot
$PgProjectBin    = Join-Path $ProjectRoot "databases\postgresql\bin"
$PgProjectData   = Join-Path $ProjectRoot "databases\postgresql\data"
$PgProjectLib    = Join-Path $ProjectRoot "databases\postgresql\lib"
$PgProjectShare  = Join-Path $ProjectRoot "databases\postgresql\share"

Write-Log "Project Root  : $ProjectRoot"
Write-Log "Project PG Bin: $PgProjectBin"

# Read config
$ConfigFile = Join-Path $ProjectRoot "config\postgresql.conf"
if (!(Test-Path $ConfigFile)) { throw "Config not found: $ConfigFile" }

$Config = @{}
Get-Content $ConfigFile | ForEach-Object {
    if ($_ -match "^([^#=]+)=(.*)$") {
        $Config[$Matches[1].Trim()] = $Matches[2].Trim()
    }
}
$ExpectedPort   = [int]$Config["POSTGRESQL_PORT"]
$AdminPassword  = $Config["POSTGRESQL_ADMIN_PASSWORD"]

Write-Log "Expected Port : $ExpectedPort"

# ---- FAST PATH: project folder already has binaries ----
if (Test-Path (Join-Path $PgProjectBin "pg_ctl.exe")) {
    Write-Log "PostgreSQL binaries already in project folder - skipping install"
    exit 0
}

Write-Log "Project folder binaries not found - checking system installation..."

# ---- Check system-installed PostgreSQL ----
$SystemBinPaths = @(
    "C:\Program Files\PostgreSQL\17\bin",
    "C:\Program Files\PostgreSQL\16\bin",
    "C:\Program Files\PostgreSQL\15\bin"
)

$SystemBin = $null
foreach ($BinPath in $SystemBinPaths) {
    if (Test-Path (Join-Path $BinPath "pg_ctl.exe")) {
        $SystemBin = $BinPath
        Write-Log "Found system PostgreSQL at: $SystemBin"
        break
    }
}

# ---- If not found anywhere, run installer ----
if (!$SystemBin) {
    Write-Log "PostgreSQL not found - running installer..."

    $InstallerDir  = Join-Path $ProjectRoot "databases\postgresql\installer"
    $InstallerFile = Join-Path $InstallerDir "postgresql-installer.exe"

    if (!(Test-Path $InstallerFile)) {
        Write-Log "Downloading installer..."
        New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest `
            -Uri "https://get.enterprisedb.com/postgresql/postgresql-17.5-1-windows-x64.exe" `
            -OutFile $InstallerFile -TimeoutSec 600
        Write-Log "Download complete"
    }

    $Process = Start-Process -FilePath $InstallerFile `
        -ArgumentList @("--mode","unattended","--superpassword",$AdminPassword,"--serverport",$ExpectedPort.ToString()) `
        -Wait -PassThru

    if ($Process.ExitCode -ne 0) {
        throw "Installer failed with exit code: $($Process.ExitCode)"
    }

    Start-Sleep -Seconds 15

    foreach ($BinPath in $SystemBinPaths) {
        if (Test-Path (Join-Path $BinPath "pg_ctl.exe")) {
            $SystemBin = $BinPath
            Write-Log "Installer placed binaries at: $SystemBin"
            break
        }
    }

    if (!$SystemBin) { throw "Binaries not found after installation" }
}

# ---- Copy binaries to project folder ----
Write-Log "Copying binaries from $SystemBin to project folder..."

$SystemRoot = Split-Path $SystemBin -Parent

New-Item -ItemType Directory -Path $PgProjectBin   -Force | Out-Null
New-Item -ItemType Directory -Path $PgProjectLib   -Force | Out-Null
New-Item -ItemType Directory -Path $PgProjectShare -Force | Out-Null

Copy-Item -Path (Join-Path $SystemRoot "bin\*")   -Destination $PgProjectBin   -Recurse -Force
Copy-Item -Path (Join-Path $SystemRoot "lib\*")   -Destination $PgProjectLib   -Recurse -Force
Copy-Item -Path (Join-Path $SystemRoot "share\*") -Destination $PgProjectShare -Recurse -Force

Write-Log "Binaries copied successfully"

# ---- initdb: initialize project data directory ----
if (!(Test-Path (Join-Path $PgProjectData "PG_VERSION"))) {
    Write-Log "Initializing data directory: $PgProjectData"
    New-Item -ItemType Directory -Path $PgProjectData -Force | Out-Null

    $env:PATH = "$PgProjectBin;$env:PATH"

    & (Join-Path $PgProjectBin "initdb.exe") `
        -D "$PgProjectData" -U postgres --encoding=UTF8

    # Set port in postgresql.conf
    Add-Content -Path (Join-Path $PgProjectData "postgresql.conf") -Value "`nport = $ExpectedPort"
    Write-Log "Data directory initialized, port set to $ExpectedPort"
} else {
    Write-Log "Data directory already initialized"
}

Write-Log "Installation complete - Binaries: $PgProjectBin | Data: $PgProjectData"