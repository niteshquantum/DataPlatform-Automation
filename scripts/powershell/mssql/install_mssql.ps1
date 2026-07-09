$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "====================================="
Write-Host "INSTALLING MSSQL SERVER"
Write-Host "====================================="
Write-Host ""

$PROJECT_ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path

$DownloadDir = "$PROJECT_ROOT\databases\mssql\downloads"

$Installer = "$DownloadDir\SQLServer2022-DEV-x64-ENU.exe"

$Service = Get-Service MSSQLSERVER -ErrorAction SilentlyContinue

if ($Service) {

    Write-Host "SQL Server already installed."
    exit 0

}

if (!(Test-Path $Installer)) {

    throw "Installer not found. Run download_mssql.ps1 first."

}

Write-Host "Installing SQL Server..."
Write-Host ""

$args = @(
"/Q",
"/ACTION=Install",
"/FEATURES=SQLEngine",
"/INSTANCENAME=MSSQLSERVER",
"/SECURITYMODE=SQL",
"/SAPWD=TerraformSA@2022!",
"/SQLSVCSTARTUPTYPE=Automatic",
"/TCPENABLED=1",
"/IACCEPTSQLSERVERLICENSETERMS"
)

$Process = Start-Process `
    -FilePath $Installer `
    -ArgumentList $args `
    -Wait `
    -PassThru

if ($Process.ExitCode -ne 0 -and $Process.ExitCode -ne 3010) {

    throw "SQL Server installation failed. ExitCode=$($Process.ExitCode)"

}

Write-Host ""
Write-Host "====================================="
Write-Host "MSSQL INSTALLATION SUCCESSFUL"
Write-Host "====================================="
Write-Host ""

exit 0