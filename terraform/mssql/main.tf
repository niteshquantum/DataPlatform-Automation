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

resource "null_resource" "download_media_windows" {

  depends_on = [
    null_resource.download_mssql_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/download_media.ps1"
  }
}

resource "null_resource" "mount_iso_windows" {

  depends_on = [
    null_resource.download_media_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/mount_iso.ps1"
  }
}

resource "null_resource" "install_mssql_windows" {

  depends_on = [
  null_resource.mount_iso_windows
]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/install_mssql.ps1"
  }
}

resource "null_resource" "validate_install_windows" {

  depends_on = [
    null_resource.install_mssql_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/validate_install.ps1"
  }
}

resource "null_resource" "dismount_iso_windows" {

  depends_on = [
    null_resource.validate_install_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/dismount_iso.ps1"
  }
}

resource "null_resource" "start_mssql_windows" {

 depends_on = [
    null_resource.dismount_iso_windows
]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/start_mssql.ps1"
  }
}

resource "null_resource" "create_database_windows" {

  depends_on = [
    null_resource.start_mssql_windows
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "../../scripts/batch/mssql/setup/create_database.bat"

  }
}


