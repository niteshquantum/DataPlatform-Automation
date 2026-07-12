terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "install_mssql_linux" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/mssql/setup/install_mssql.sh"
  }
}

resource "null_resource" "start_mssql_linux" {
  depends_on = [null_resource.install_mssql_linux]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/mssql/setup/start_mssql.sh"
  }
}
