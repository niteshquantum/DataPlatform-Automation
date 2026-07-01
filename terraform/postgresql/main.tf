terraform {

  required_version = ">= 1.13.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {

  project_root   = abspath("${path.module}/../..")
  powershell_dir = "${local.project_root}/scripts/powershell/postgresql"

}

#############################################################
# P1 Detect Operating System
#############################################################

resource "null_resource" "p1_detect_os" {

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "$env:OS"
  }
}

#############################################################
# P2 Install PostgreSQL (WINDOWS)
#############################################################

resource "null_resource" "p2_install_postgresql" {

  depends_on = [
    null_resource.p1_detect_os
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File \"${local.powershell_dir}/install_windows.ps1\""
  }
}

#############################################################
# P3 Start PostgreSQL (WINDOWS)
#############################################################

resource "null_resource" "p3_start_postgresql" {

  depends_on = [
    null_resource.p2_install_postgresql
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File \"${local.powershell_dir}/start_postgresql.ps1\""
  }
}

#############################################################
# P4 Validate PostgreSQL (WINDOWS)
#############################################################

resource "null_resource" "p4_validate_postgresql" {

  depends_on = [
    null_resource.p3_start_postgresql
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File \"${local.powershell_dir}/validate_postgresql.ps1\""
  }
}

#############################################################
# INSTALL POSTGRESQL (LINUX)
#############################################################

resource "null_resource" "install_postgresql_linux" {

  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/postgresql/setup/install_postgresql.sh"
  }
}

#############################################################
# START POSTGRESQL (LINUX)
#############################################################

resource "null_resource" "start_postgresql_linux" {

  depends_on = [
    null_resource.install_postgresql_linux
  ]

  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/postgresql/setup/start_postgresql.sh"
  }
}