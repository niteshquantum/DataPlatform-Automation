@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo CREATE DATABASE
echo =====================================
echo.

set "ROOT=%CD%"
set "CONFIG_FILE=%ROOT%\config\windows\mssql.conf"

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
if /I "%%A"=="MSSQL_HOST" set "MSSQL_HOST=%%B"
if /I "%%A"=="MSSQL_PORT" set "MSSQL_PORT=%%B"
if /I "%%A"=="MSSQL_DB" set "MSSQL_DB=%%B"
if /I "%%A"=="MSSQL_USER" set "MSSQL_USER=%%B"
if /I "%%A"=="MSSQL_PASSWORD" set "MSSQL_PASSWORD=%%B"
)

sqlcmd ^
-S %MSSQL_HOST%,%MSSQL_PORT% ^
-U %MSSQL_USER% ^
-P %MSSQL_PASSWORD% ^
-C ^
-Q "IF DB_ID('%MSSQL_DB%') IS NULL CREATE DATABASE [%MSSQL_DB%]"

if errorlevel 1 (
echo DATABASE CREATION FAILED
exit /b 1
)

echo DATABASE READY : %MSSQL_DB%

exit /b 0