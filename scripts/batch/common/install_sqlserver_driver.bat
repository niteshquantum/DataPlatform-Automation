@echo off
setlocal

echo.
echo =====================================
echo INSTALLING SQL SERVER JDBC DRIVER
echo =====================================
echo.

powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\download_sqlserver_driver.ps1"

if errorlevel 1 (
echo ERROR: SQL SERVER JDBC DRIVER INSTALL FAILED
exit /b 1
)

echo.
echo SQL SERVER JDBC DRIVER INSTALLED
echo.

exit /b 0