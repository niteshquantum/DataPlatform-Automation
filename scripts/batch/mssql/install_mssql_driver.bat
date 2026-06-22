@echo off
setlocal

echo.
echo =====================================
echo INSTALLING MSSQL JDBC DRIVER
echo =====================================
echo.

powershell -ExecutionPolicy Bypass ^
-File "%~dp0..\..\powershell\download_mssql_driver.ps1"

if errorlevel 1 (
echo ERROR: MSSQL JDBC DRIVER INSTALL FAILED
exit /b 1
)

echo.
echo MSSQL JDBC DRIVER INSTALL SUCCESSFUL
echo.

exit /b 0
