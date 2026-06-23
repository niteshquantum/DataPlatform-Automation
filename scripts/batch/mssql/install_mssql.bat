@echo off

echo.
echo =====================================
echo INSTALLING MSSQL
echo =====================================
echo.

powershell -ExecutionPolicy Bypass ^
-File scripts\powershell\install_mssql.ps1

if errorlevel 1 (
echo MSSQL INSTALL FAILED
exit /b 1
)

echo.
echo MSSQL INSTALL SUCCESSFUL
echo.

exit /b 0