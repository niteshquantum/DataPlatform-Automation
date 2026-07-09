@echo off
setlocal

echo.
echo =====================================
echo VALIDATING TOOLS
echo =====================================
echo.

REM =====================================
REM TERRAFORM
REM =====================================

call "%~dp0..\..\common\set_project_root.bat"
set "ROOT=%PROJECT_ROOT%"

if not exist "%ROOT%\tools\terraform\terraform.exe" (
echo ERROR: TERRAFORM NOT FOUND
exit /b 1
)

echo Checking Terraform...
"%ROOT%\tools\terraform\terraform.exe" version
echo Checking Liquibase...
call "%~dp0..\..\common\validate_liquibase.bat"
if errorlevel 1 exit /b 1

echo Checking MySQL Driver...
call "%~dp0validate_mysql_driver.bat"
if errorlevel 1 exit /b 1

echo TERRAFORM VALIDATED




echo.
echo =====================================
echo TOOLS VALIDATED SUCCESSFULLY
echo =====================================
echo.

exit /b 0
