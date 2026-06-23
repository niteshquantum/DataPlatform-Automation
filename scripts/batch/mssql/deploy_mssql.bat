@echo off
setlocal

REM =====================================
REM ROOT PATH
REM =====================================

set ROOT=%~dp0..\..\..

REM =====================================
REM TERRAFORM PATH
REM =====================================

set TF=%ROOT%\tools\terraform\terraform.exe

REM =====================================
REM CHECK TERRAFORM
REM =====================================

if not exist "%TF%" (
echo Terraform is not installed.
echo Run install_terraform.bat first.
exit /b 1
)

REM =====================================
REM GO TO MSSQL TERRAFORM
REM =====================================

cd /d "%ROOT%\terraform\mssql\windows"

echo.
echo =====================================
echo TERRAFORM INIT
echo =====================================
echo.

"%TF%" init

if errorlevel 1 exit /b 1

echo.
echo =====================================
echo TERRAFORM APPLY
echo =====================================
echo.

"%TF%" apply -auto-approve

if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MSSQL DEPLOYMENT SUCCESSFUL
echo =====================================
echo.

exit /b 0