terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "download_mysql_windows" {

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

    if (!(Test-Path "..\..\databases\mysql")) {
    New-Item -ItemType Directory -Path "..\..\databases\mysql" -Force
}

$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest -Uri "https://cdn.mysql.com/Downloads/MySQL-9.7/mysql-9.7.0-winx64.zip" -OutFile "..\..\databases\mysql\mysql.zip" -UseBasicParsing

if (!(Test-Path "..\..\databases\mysql\mysql.zip")) {
    throw "mysql.zip download failed"
}

Write-Host "Download Complete"

EOT
  }
}

resource "null_resource" "extract_mysql_windows" {

  depends_on = [null_resource.download_mysql_windows]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

if (Test-Path "..\..\databases\mysql\server") {
    Remove-Item "..\..\databases\mysql\server" -Recurse -Force
}

Expand-Archive -Path "..\..\databases\mysql\mysql.zip" -DestinationPath "..\..\databases\mysql" -Force

$folder = Get-ChildItem "..\..\databases\mysql" -Directory | Where-Object {
    $_.Name -like "mysql-*"
} | Select-Object -First 1

if ($null -eq $folder) {
    throw "MySQL extraction failed"
}

Rename-Item $folder.FullName "server" -Force

Write-Host "Extraction Complete"

EOT
  }
}

resource "null_resource" "init_mysql_windows" {

  depends_on = [null_resource.extract_mysql_windows]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

if (!(Test-Path "..\..\databases\mysql\data")) {
    New-Item -ItemType Directory -Path "..\..\databases\mysql\data" -Force
}

& "..\..\databases\mysql\server\bin\mysqld.exe" --initialize-insecure --basedir="..\..\databases\mysql\server" --datadir="..\..\databases\mysql\data"

if (!(Test-Path "..\..\databases\mysql\data\ibdata1")) {
    throw "MySQL initialization failed"
}

Write-Host "MySQL Initialized Successfully"

EOT
  }
}


resource "null_resource" "start_mysql_windows" {
 
  depends_on = [null_resource.init_mysql_windows]
 
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
 
    command = "powershell -ExecutionPolicy Bypass -File ../../scripts/powershell/start_mysql.ps1"
  }
}


resource "null_resource" "install_mysql_linux" {

  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/install_mysql.sh"
  }
}

resource "null_resource" "start_mysql_linux" {

  depends_on = [null_resource.install_mysql_linux]

  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = "../../scripts/bash/start_mysql.sh"
  }
}

