@echo off
setlocal

echo.
echo =====================================
echo VALIDATING TOOLS
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

set "ROOT=%PROJECT_ROOT%"

REM =====================================
REM TERRAFORM
REM =====================================

if not exist "%ROOT%\tools\terraform\terraform.exe" (
    echo ERROR: TERRAFORM NOT FOUND
    exit /b 1
)

echo Checking Terraform...
"%ROOT%\tools\terraform\terraform.exe" version

echo TERRAFORM VALIDATED

echo.
echo =====================================
echo TOOLS VALIDATED SUCCESSFULLY
echo =====================================
echo.

exit /b 0