$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "INSTALLING MSSQL SERVER"
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
$Password = $Config["MSSQL_PASSWORD"]

# =====================================
# SERVICE NAME
# =====================================

if ($Instance -eq "MSSQLSERVER") {
    $ServiceName = "MSSQLSERVER"
}
else {
    $ServiceName = "MSSQL`$$Instance"
}

# =====================================
# CHECK EXISTING INSTALLATION
# =====================================

$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($Service) {

    Write-Host "SQL Server instance '$Instance' already installed."
    exit 0

}

# =====================================
# ISO PATH
# =====================================

$IsoPath = Join-Path `
    $PROJECT_ROOT `
    "databases\mssql\media\SQLServer2022-x64-ENU-Dev.iso"

if (!(Test-Path $IsoPath)) {

    throw "SQL Server ISO not found.`n$IsoPath"

}

Write-Host "ISO Found"
Write-Host $IsoPath
Write-Host ""

# =====================================
# MOUNT ISO
# =====================================

Write-Host "Mounting ISO..."
Write-Host ""

Mount-DiskImage `
    -ImagePath $IsoPath `
    -StorageType ISO

Start-Sleep -Seconds 5

# =====================================
# GET DRIVE LETTER
# =====================================

$Drive = Get-DiskImage -ImagePath $IsoPath |
    Get-Volume

$SetupExe = Join-Path ($Drive.DriveLetter + ":\") "setup.exe"

if (!$Drive) {

    throw "Unable to detect mounted SQL Server ISO."

}

Write-Host "Drive Letter : $($Drive.DriveLetter)"
Write-Host "Setup Path   : $SetupExe"

if (!(Test-Path $SetupExe)) {

    throw "setup.exe not found.`n$SetupExe"

}

Write-Host "Setup Found : $SetupExe"
Write-Host ""

Write-Host ""
Write-Host "Generating Configuration File..."
Write-Host ""

& "$PROJECT_ROOT\scripts\powershell\mssql\generate_configuration_file.ps1"

$ConfigurationFile = Join-Path `
    $PROJECT_ROOT `
    "databases\mssql\ConfigurationFile.ini"

if (!(Test-Path $ConfigurationFile)) {
    throw "Configuration file not found.`n$ConfigurationFile"
}

Write-Host "Starting unattended SQL Server installation..."
Write-Host ""

$Arguments = @(
    "/ConfigurationFile=`"$ConfigurationFile`""
)

$Process = Start-Process `
    -FilePath $SetupExe `
    -ArgumentList $Arguments `
    -Wait `
    -PassThru

if ($Process.ExitCode -ne 0 -and $Process.ExitCode -ne 3010) {

    throw "Installation failed. Exit Code : $($Process.ExitCode)"

}

Write-Host ""
Write-Host "Unmounting SQL Server ISO..."
Write-Host ""

Dismount-DiskImage `
    -ImagePath $IsoPath `
    -ErrorAction SilentlyContinue

# =====================================
# VERIFY SERVICE
# =====================================

$Service = Get-Service `
    -Name $ServiceName `
    -ErrorAction SilentlyContinue

if (!$Service) {

    throw "SQL Server service not created."

}

Write-Host ""
Write-Host "====================================="
Write-Host "INSTALLATION SUCCESSFUL"
Write-Host "====================================="
Write-Host ""

Write-Host "Service Name : $($Service.Name)"
Write-Host "Status       : $($Service.Status)"
Write-Host "Start Type   : $($Service.StartType)"

exit 0