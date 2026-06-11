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
REM GO TO MYSQL TERRAFORM
REM =====================================

cd /d "%ROOT%\terraform\mysql"

echo.
echo =====================================
echo TERRAFORM INIT
echo =====================================
echo.

"%TF%" init

echo.
echo =====================================
echo TERRAFORM APPLY
echo =====================================
echo.

"%TF%" apply ^
-target=null_resource.download_mysql_windows ^
-target=null_resource.extract_mysql_windows ^
-target=null_resource.init_mysql_windows ^
-target=null_resource.start_mysql_windows ^
-auto-approve