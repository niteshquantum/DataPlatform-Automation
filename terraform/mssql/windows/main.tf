terraform {
required_providers {
null = {
source  = "hashicorp/null"
version = "~> 3.2"
}
}
}

resource "null_resource" "verify_mssql" {

provisioner "local-exec" {

    
    interpreter = ["PowerShell", "-Command"]

    command = <<-PSEOF
    

Write-Host ""
Write-Host "====================================="
Write-Host "VERIFY MSSQL INSTANCE"
Write-Host "====================================="

$svc = Get-Service "MSSQL`$DMSQL" -ErrorAction SilentlyContinue

if (!$svc) {
throw "DMSQL instance not found"
}

Write-Host "Instance Found"
Write-Host "Service : MSSQL`$DMSQL"
Write-Host "Status  : $($svc.Status)"

PSEOF

}
}
