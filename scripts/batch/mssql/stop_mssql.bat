@echo off

powershell -ExecutionPolicy Bypass -Command ^
"Stop-Service MSSQLSERVER"

if errorlevel 1 (
echo MSSQL STOP FAILED
exit /b 1
)

echo MSSQL STOPPED

exit /b 0