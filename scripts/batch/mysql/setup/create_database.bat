@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo CREATE DATABASE
echo =====================================
echo.

REM =====================================
REM PROJECT ROOT
REM =====================================

set "ROOT=%~dp0..\..\..\.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

set "CONFIG_FILE=%ROOT%\config\windows\mysql.conf"

if not exist "%CONFIG_FILE%" (
    echo ERROR: CONFIG FILE NOT FOUND
    echo Expected: %CONFIG_FILE%
    exit /b 1
)

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
    if /I "%%A"=="MYSQL_HOST" set "MYSQL_HOST=%%B"
    if /I "%%A"=="MYSQL_PORT" set "MYSQL_PORT=%%B"
    if /I "%%A"=="MYSQL_DB" set "MYSQL_DB=%%B"
    if /I "%%A"=="MYSQL_USER" set "MYSQL_USER=%%B"
    if /I "%%A"=="MYSQL_PASSWORD" set "MYSQL_PASSWORD=%%B"
)

if not defined MYSQL_HOST (
    echo ERROR: MYSQL_HOST NOT DEFINED
    exit /b 1
)

if not defined MYSQL_PORT (
    echo ERROR: MYSQL_PORT NOT DEFINED
    exit /b 1
)

if not defined MYSQL_DB (
    echo ERROR: MYSQL_DB NOT DEFINED
    exit /b 1
)

if not defined MYSQL_USER (
    echo ERROR: MYSQL_USER NOT DEFINED
    exit /b 1
)

set "MYSQL_EXE=%ROOT%\databases\mysql\server\bin\mysql.exe"

if not exist "%MYSQL_EXE%" (
    echo ERROR: MYSQL CLIENT NOT FOUND
    echo Expected: %MYSQL_EXE%
    exit /b 1
)

echo Host     : %MYSQL_HOST%
echo Port     : %MYSQL_PORT%
echo Database : %MYSQL_DB%
echo User     : %MYSQL_USER%
echo.

set "MYSQL_PASSWORD_OPTION="
if defined MYSQL_PASSWORD (
    set "MYSQL_PASSWORD_OPTION=-p%MYSQL_PASSWORD%"
)

set "CHECK_DB_SQL=SHOW DATABASES LIKE '%MYSQL_DB%';"
"%MYSQL_EXE%" -h %MYSQL_HOST% -u %MYSQL_USER% -P %MYSQL_PORT% %MYSQL_PASSWORD_OPTION% -e "%CHECK_DB_SQL%" > "%TEMP%\mysql_db_check.txt" 2>nul

if errorlevel 1 (
    echo ERROR: DATABASE CHECK FAILED
    exit /b 1
)

findstr /I /C:"%MYSQL_DB%" "%TEMP%\mysql_db_check.txt" >nul
if not errorlevel 1 (
    echo Database already exists.
    echo Reusing existing database.
) else (
    echo Database does not exist.
    echo Creating database.
    "%MYSQL_EXE%" -h %MYSQL_HOST% -u %MYSQL_USER% -P %MYSQL_PORT% %MYSQL_PASSWORD_OPTION% -e "CREATE DATABASE IF NOT EXISTS %MYSQL_DB%;"
    if errorlevel 1 (
        echo ERROR: DATABASE CREATION FAILED
        exit /b 1
    )
)

echo.
echo DATABASE READY : %MYSQL_DB%
echo.
echo =====================================
echo DATABASE VALIDATED
echo =====================================
echo.

exit /b 0