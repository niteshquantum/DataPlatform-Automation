@echo off
setlocal

echo.
echo =====================================
echo STARTING MSSQL
echo =====================================
echo.

set "CONFIG_FILE=config\windows\mssql.conf"

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
if /I "%%A"=="MSSQL_INSTANCE" set "MSSQL_INSTANCE=%%B"
)

if /I "%MSSQL_INSTANCE%"=="MSSQLSERVER" (
set "SERVICE_NAME=MSSQLSERVER"
) else (
set "SERVICE_NAME=MSSQL$%MSSQL_INSTANCE%"
)

sc query "%SERVICE_NAME%" >nul 2>&1

if errorlevel 1 (
echo MSSQL SERVICE NOT FOUND : %SERVICE_NAME%
exit /b 1
)

net start "%SERVICE_NAME%" >nul 2>&1

echo MSSQL START SUCCESSFUL
echo SERVICE : %SERVICE_NAME%

exit /b 0
