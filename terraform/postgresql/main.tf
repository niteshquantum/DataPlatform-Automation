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
# WINDOWS RESOURCES
#############################################################

resource "null_resource" "p1_detect_os" {

  count = var.target_os == "windows" ? 1 : 0

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "$env:OS"
  }
}

resource "null_resource" "p2_install_postgresql" {

  count = var.target_os == "windows" ? 1 : 0

  depends_on = [
    null_resource.p1_detect_os
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File \"${local.powershell_dir}/install_windows.ps1\""
  }
}

resource "null_resource" "p3_start_postgresql" {

  count = var.target_os == "windows" ? 1 : 0

  depends_on = [
    null_resource.p2_install_postgresql
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = "powershell -ExecutionPolicy Bypass -File \"${local.powershell_dir}/start_postgresql.ps1\""
  }
}

resource "null_resource" "p4_validate_postgresql" {

  count = var.target_os == "windows" ? 1 : 0

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
# LINUX RESOURCES
#############################################################

resource "null_resource" "install_postgresql_linux" {

  count = var.target_os == "linux" ? 1 : 0

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/postgresql/setup/install_postgresql.sh"
  }
}

resource "null_resource" "start_postgresql_linux" {

  count = var.target_os == "linux" ? 1 : 0

  depends_on = [
    null_resource.install_postgresql_linux
  ]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/postgresql/setup/start_postgresql.sh"
  }
}