terraform {
required_providers {
null = {
source  = "hashicorp/null"
version = "~> 3.2"
}
}
}

locals {
sql_instance     = var.sql_instance
sql_port         = var.sql_port
sql_sa_password  = var.sql_sa_password
sql_database     = var.sql_database
sql_installer    = var.sql_installer
sql_download_url = var.sql_download_url
}

# --------------------------------------------------

# W1 - Verify SQL Server Service

# --------------------------------------------------

resource "null_resource" "w1_verify_sqlserver" {

provisioner "local-exec" {


    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF


Write-Host ""
Write-Host "====================================="
Write-Host "W1 - VERIFY SQL SERVER"
Write-Host "====================================="

$svc = Get-Service MSSQLSERVER -ErrorAction SilentlyContinue

if ($svc) {
Write-Host "SQL Server service found"
}
else {
Write-Host "SQL Server service not found"
}

PSEOF
}
}

# --------------------------------------------------

# W2 - Start MSSQLSERVER

# --------------------------------------------------

resource "null_resource" "w2_start_sqlserver" {

depends_on = [null_resource.w1_verify_sqlserver]

provisioner "local-exec" {


    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF


Write-Host ""
Write-Host "====================================="
Write-Host "W2 - START SQL SERVER"
Write-Host "====================================="

$svc = Get-Service MSSQLSERVER -ErrorAction SilentlyContinue

if ($svc) {


    if ($svc.Status -ne "Running") {
        Start-Service MSSQLSERVER
        Start-Sleep -Seconds 10
    }

    Write-Host "SQL Server Status:"
    Get-Service MSSQLSERVER


}
else {
throw "MSSQLSERVER service not found"
}

PSEOF
}
}

# --------------------------------------------------

# W3 - Enable Mixed Mode

# --------------------------------------------------

resource "null_resource" "w3_enable_mixed_mode" {

depends_on = [null_resource.w2_start_sqlserver]

provisioner "local-exec" {

    
    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF
   

Write-Host ""
Write-Host "====================================="
Write-Host "W3 - ENABLE MIXED MODE"
Write-Host "====================================="

$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQLServer"

if (Test-Path $regPath) {

   
    Set-ItemProperty `
        -Path $regPath `
        -Name LoginMode `
        -Value 2

    Write-Host "Mixed Mode Enabled"
    

}
else {
Write-Host "Registry Path Not Found"
}

PSEOF
}
}

# --------------------------------------------------

# W4 - Restart SQL Server

# --------------------------------------------------

resource "null_resource" "w4_restart_sqlserver" {

depends_on = [null_resource.w3_enable_mixed_mode]

provisioner "local-exec" {

    
    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF
    

Restart-Service MSSQLSERVER -Force

Start-Sleep -Seconds 15

Get-Service MSSQLSERVER

PSEOF
}
}

# --------------------------------------------------

# W5 - Enable SA Login

# --------------------------------------------------

resource "null_resource" "w5_enable_sa" {

depends_on = [null_resource.w4_restart_sqlserver]

provisioner "local-exec" {

    
    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF
    

$sqlcmd = (Get-Command sqlcmd).Source

& $sqlcmd `-S localhost`
-E `
-Q "
ALTER LOGIN sa ENABLE;
ALTER LOGIN sa WITH PASSWORD='${local.sql_sa_password}';
"

if ($LASTEXITCODE -ne 0) {
throw 'Failed enabling SA login'
}

Write-Host "SA Login Enabled"

PSEOF
}
}

# --------------------------------------------------

# W6 - Verify SA Login

# --------------------------------------------------

resource "null_resource" "w6_verify_sa" {

depends_on = [null_resource.w5_enable_sa]

provisioner "local-exec" {

    
    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF
    

$sqlcmd = (Get-Command sqlcmd).Source

& $sqlcmd `-S localhost`
-U sa `-P "${local.sql_sa_password}"`
-Q "SELECT @@VERSION"

if ($LASTEXITCODE -ne 0) {
throw 'SA login verification failed'
}

Write-Host "SA Login Verified"

PSEOF
}
}

# --------------------------------------------------

# W7 - Final Verification

# --------------------------------------------------

resource "null_resource" "w7_final_verify" {

depends_on = [null_resource.w6_verify_sa]

provisioner "local-exec" {

    
    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF
    

Write-Host ""
Write-Host "====================================="
Write-Host "MSSQL TERRAFORM COMPLETE"
Write-Host "====================================="

Write-Host "Instance : ${local.sql_instance}"
Write-Host "Port     : ${local.sql_port}"
Write-Host "Database : ${local.sql_database}"

PSEOF
}
}
