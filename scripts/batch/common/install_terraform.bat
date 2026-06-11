@echo off
setlocal

REM =====================================
REM ROOT PATH
REM =====================================

set ROOT=%~dp0..\..\..

if not exist "%ROOT%\tools" (
    mkdir "%ROOT%\tools"
)

REM =====================================
REM TERRAFORM PATH
REM =====================================

set TF_DIR=%ROOT%\tools\terraform

if not exist "%TF_DIR%" (
    mkdir "%TF_DIR%"
)

REM =====================================
REM CHECK INSTALLATION
REM =====================================

if exist "%TF_DIR%\terraform.exe" (

    echo Terraform already installed.
    echo Skipping download...

) else (

    echo Downloading Terraform...

    powershell -Command "Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/1.13.0/terraform_1.13.0_windows_amd64.zip' -OutFile '%ROOT%\tools\terraform.zip'"

    echo Extracting Terraform...

    powershell -Command "Expand-Archive '%ROOT%\tools\terraform.zip' -DestinationPath '%TF_DIR%' -Force"

    del "%ROOT%\tools\terraform.zip"

    echo Terraform Installed Successfully.
)
