```bat
@echo off
setlocal

echo.
echo =====================================
echo DEPLOYING POSTGRESQL
echo =====================================
echo.

REM =====================================
REM PROJECT ROOT
REM =====================================

call "%~dp0..\..\common\set_project_root.bat"

set "ROOT=%PROJECT_ROOT%"
set "TF=%ROOT%\tools\terraform\terraform.exe"

REM =====================================
REM CHECK TERRAFORM
REM =====================================

if not exist "%TF%" (
    echo ERROR: Terraform not found.
    exit /b 1
)

REM =====================================
REM GO TO TERRAFORM DIRECTORY
REM =====================================

cd /d "%ROOT%\terraform\postgresql"

if errorlevel 1 (
    echo ERROR: Unable to access Terraform directory.
    exit /b 1
)

echo.
echo =====================================
echo TERRAFORM INIT
echo =====================================
echo.

"%TF%" init

if errorlevel 1 (
    echo ERROR: Terraform initialization failed.
    exit /b 1
)

echo.
echo =====================================
echo TERRAFORM APPLY
echo =====================================
echo.

"%TF%" apply -auto-approve

if errorlevel 1 (
    echo ERROR: Terraform deployment failed.
    exit /b 1
)

echo.
echo =====================================
echo POSTGRESQL DEPLOYMENT COMPLETED
echo =====================================
echo.

exit /b 0
```
