terraform {
required_version = ">= 1.5"

required_providers {
null = {
source  = "hashicorp/null"
version = "~> 3.2"
}
}
}

resource "null_resource" "download_mongodb_windows" {

provisioner "local-exec" {


interpreter = ["PowerShell", "-Command"]

command = <<EOT


if (!(Test-Path "..\..\databases\mongodb")) {
New-Item -ItemType Directory -Path "..\..\databases\mongodb" -Force
}

$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest -Uri "https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-8.0.12.zip" -OutFile "..\\..\\databases\\mongodb\\mongodb.zip"

Write-Host "MongoDB ZIP Download Complete"

EOT

}
}

resource "null_resource" "extract_mongodb_windows" {

depends_on = [
null_resource.download_mongodb_windows
]

provisioner "local-exec" {


interpreter = ["PowerShell", "-Command"]

command = <<EOT


if (Test-Path "..\..\databases\mongodb\server") {
Remove-Item "..\..\databases\mongodb\server" -Recurse -Force
}

Expand-Archive -Path "..\..\databases\mongodb\mongodb.zip" -DestinationPath "..\..\databases\mongodb" -Force

$folder = Get-ChildItem "..\..\databases\mongodb" -Directory | Where-Object {
$_.Name -like "mongodb-*"
} | Select-Object -First 1

if ($null -eq $folder) {
throw "MongoDB extraction failed"
}

Rename-Item $folder.FullName "server" -Force

Write-Host "MongoDB Extraction Complete"

EOT

}
}
resource "null_resource" "download_mongosh_windows" {

  depends_on = [
    null_resource.extract_mongodb_windows
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest -Uri "https://downloads.mongodb.com/compass/mongosh-2.5.8-win32-x64.zip" -OutFile "..\\..\\databases\\mongodb\\mongosh.zip"

Write-Host "mongosh ZIP Download Complete"

EOT

  }
}
resource "null_resource" "extract_mongosh_windows" {

  depends_on = [
    null_resource.download_mongosh_windows
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<EOT

if (Test-Path "..\\..\\databases\\mongodb\\mongosh") {
    Remove-Item "..\\..\\databases\\mongodb\\mongosh" -Recurse -Force
}

Expand-Archive -Path "..\\..\\databases\\mongodb\\mongosh.zip" -DestinationPath "..\\..\\databases\\mongodb" -Force

$folder = Get-ChildItem "..\\..\\databases\\mongodb" -Directory | Where-Object {
    $_.Name -like "mongosh-*"
} | Select-Object -First 1

Rename-Item $folder.FullName "mongosh"

Write-Host "mongosh Extraction Complete"

EOT

  }
}
resource "null_resource" "init_mongodb_windows" {

depends_on = [
null_resource.extract_mongodb_windows
]

provisioner "local-exec" {


interpreter = ["PowerShell", "-Command"]

command = <<EOT


if (!(Test-Path "..\..\databases\mongodb\data")) {
New-Item -ItemType Directory -Path "..\..\databases\mongodb\data" -Force
}

if (!(Test-Path "..\..\databases\mongodb\logs")) {
New-Item -ItemType Directory -Path "..\..\databases\mongodb\logs" -Force
}

if (!(Test-Path "..\..\databases\mongodb\config")) {
New-Item -ItemType Directory -Path "..\..\databases\mongodb\config" -Force
}

Write-Host "MongoDB directories created successfully"

EOT

}
}


resource "null_resource" "mongodb_windows" {

depends_on = [
null_resource.init_mongodb_windows
]

triggers = {
mongodb_version = "8.0.12"
script_version = "2.3"
mongodb_port = var.mongodb_port
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
