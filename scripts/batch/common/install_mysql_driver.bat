@echo off

echo.
echo =====================================
echo INSTALLING MYSQL DRIVER
echo =====================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\powershell\download_mysql_driver.ps1"

if errorlevel 1 (
    echo.
    echo MYSQL DRIVER INSTALLATION FAILED
    exit /b 1
)

echo.
echo MYSQL DRIVER INSTALLATION SUCCESSFUL
echo.