@echo off
setlocal

echo.
echo =====================================
echo RESETTING POSTGRESQL TERRAFORM STATE
echo =====================================
echo.

REM =====================================
REM PROJECT ROOT
REM =====================================

call "%~dp0..\..\common\set_project_root.bat"

if errorlevel 1 (
    echo ERROR: Unable to determine project root.
    exit /b 1
)

set "ROOT=%PROJECT_ROOT%"

set "RESET_SCRIPT=%ROOT%\scripts\powershell\postgresql\cleanup\reset_terraform_state.ps1"

REM =====================================
REM CHECK POWERSHELL SCRIPT
REM =====================================

if not exist "%RESET_SCRIPT%" (
    echo ERROR: PostgreSQL Terraform reset script not found:
    echo %RESET_SCRIPT%
    exit /b 1
)

REM =====================================
REM RESET TERRAFORM STATE
REM =====================================

powershell.exe ^
-NoProfile ^
-NonInteractive ^
-ExecutionPolicy Bypass ^
-File "%RESET_SCRIPT%"

if errorlevel 1 (
    echo ERROR: PostgreSQL Terraform state reset failed.
    exit /b 1
)

echo.
echo =====================================
echo POSTGRESQL TERRAFORM RESET COMPLETED
echo =====================================
echo.

exit /b 0