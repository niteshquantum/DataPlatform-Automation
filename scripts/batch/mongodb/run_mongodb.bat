@echo off
setlocal

set TERRAFORM_EXE=%~dp0..\..\..\tools\terraform\terraform.exe

cd /d "%~dp0..\..\..\terraform\mongodb"

"%TERRAFORM_EXE%" init

if errorlevel 1 (
    echo Terraform Init Failed
    exit /b 1
)

"%TERRAFORM_EXE%" apply -auto-approve

if errorlevel 1 (
    echo Terraform Apply Failed
    exit /b 1
)

echo MongoDB Terraform Completed Successfully

