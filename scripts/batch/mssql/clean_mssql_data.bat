@echo off
setlocal

echo.
echo =====================================
echo CLEANING MSSQL DATABASE
echo =====================================
echo.

set "ROOT=%CD%"
set "CONFIG_FILE=%ROOT%\config\windows\mssql.conf"

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
if /I "%%A"=="MSSQL_HOST" set "MSSQL_HOST=%%B"
if /I "%%A"=="MSSQL_PORT" set "MSSQL_PORT=%%B"
if /I "%%A"=="MSSQL_USER" set "MSSQL_USER=%%B"
if /I "%%A"=="MSSQL_PASSWORD" set "MSSQL_PASSWORD=%%B"
if /I "%%A"=="MSSQL_DB" set "MSSQL_DB=%%B"
)

sqlcmd ^
-S %MSSQL_HOST%,%MSSQL_PORT% ^
-U %MSSQL_USER% ^
-P "%MSSQL_PASSWORD%" ^
-C ^
-Q "IF DB_ID('%MSSQL_DB%') IS NOT NULL
BEGIN
    ALTER DATABASE [%MSSQL_DB%]
    SET SINGLE_USER
    WITH ROLLBACK IMMEDIATE;

    DROP DATABASE [%MSSQL_DB%];
END"

if errorlevel 1 (
    echo DATABASE CLEAN FAILED
    exit /b 1
)

echo.
echo DATABASE REMOVED SUCCESSFULLY
echo.

exit /b 0