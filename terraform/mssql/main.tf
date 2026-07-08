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

# --- FIX: moved to depend on install_mssql_windows (was dismount_iso_windows).
#     start_mssql.ps1 is the script that writes the static TCP port to the
#     registry and starts the service - validate_install.ps1 (next resource)
#     checks that exact registry port, so start_mssql must run BEFORE
#     validate_install, not after it. ---
resource "null_resource" "start_mssql_windows" {

 depends_on = [
    null_resource.install_mssql_windows
]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/start_mssql.ps1"
  }
}
# --- END FIX ---

# --- FIX: moved to depend on start_mssql_windows (was install_mssql_windows).
#     This is the root cause fix: validate_install.ps1 reads the TCP port
#     from the registry, which is only written by start_mssql.ps1. Running
#     validation before the port is configured produced:
#     "Registry configuration port '' does not match mssql.conf target
#     port '1533'." ---
resource "null_resource" "validate_install_windows" {

  depends_on = [
    null_resource.start_mssql_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/validate_install.ps1"
  }
}
# --- END FIX ---

resource "null_resource" "dismount_iso_windows" {

  depends_on = [
    null_resource.validate_install_windows
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/mssql/dismount_iso.ps1"
  }
}

# --- FIX: moved to depend on dismount_iso_windows (was start_mssql_windows),
#     since start_mssql_windows now runs earlier in the chain above. This
#     preserves the same single, unambiguous linear order end-to-end. ---
resource "null_resource" "create_database_windows" {

  depends_on = [
    null_resource.dismount_iso_windows
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "cmd /c ../../scripts/batch/mssql/setup/create_database.bat"

  }
}
# --- END FIX ---
