@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo STARTING MSSQL
echo =====================================
echo.

set CONFIG_FILE=config\windows\mssql.conf

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
if /I "%%A"=="MSSQL_INSTANCE" set MSSQL_INSTANCE=%%B
)

sc query %MSSQL_INSTANCE% >nul 2>&1

if errorlevel 1 (
echo MSSQL SERVICE NOT FOUND : %MSSQL_INSTANCE%
exit /b 1
)

net start %MSSQL_INSTANCE% >nul 2>&1

echo MSSQL START SUCCESSFUL

exit /b 0
