terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

#################################################
# WINDOWS
#################################################

resource "null_resource" "download_mssql_windows" {

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/download_mssql.ps1"
  }
}

resource "null_resource" "install_mssql_windows" {

  depends_on = [
    null_resource.download_mssql_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/install_mssql.ps1"
  }
}

resource "null_resource" "start_mssql_windows" {

  depends_on = [
    null_resource.install_mssql_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/start_mssql.ps1"
  }
}

#################################################
# LINUX
#################################################

resource "null_resource" "install_mssql_linux" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/mssql/setup/install_mssql.sh"
  }
}

resource "null_resource" "start_mssql_linux" {

  depends_on = [
    null_resource.install_mssql_linux
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/mssql/setup/start_mssql.sh"
  }
}