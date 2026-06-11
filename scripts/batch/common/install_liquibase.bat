@echo off

echo.
echo =====================================
echo INSTALLING LIQUIBASE
echo =====================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\powershell\download_liquibase.ps1"

if errorlevel 1 (
    echo.
    echo LIQUIBASE INSTALLATION FAILED
    exit /b 1
)

echo.
echo LIQUIBASE INSTALLATION SUCCESSFUL
echo.