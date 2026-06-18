terraform {
  required_version = ">= 1.5"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "mongodb_windows" {

  triggers = {
    mongodb_version    = "8.3.2"
    script_version     = "2.3"
    mongodb_port       = var.mongodb_port
    use_existing_mongodb = tostring(var.use_existing_mongodb)
  }
provisioner "local-exec" {

  environment = {
    MONGODB_PORT         = tostring(var.mongodb_port)
    USE_EXISTING_MONGODB = tostring(var.use_existing_mongodb)
  }

  interpreter = [
    "PowerShell",
    "-ExecutionPolicy",
    "Bypass",
    "-File"
  ]

 command = "${path.module}/../../scripts/powershell/mongodb/install_windows.ps1"
}
}
