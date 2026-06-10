@echo off
setlocal EnableDelayedExpansion

REM =====================================
REM ROOT PATH
REM =====================================

set ROOT=%~dp0..\..\..

REM =====================================
REM CONFIG FILE
REM =====================================

set CONFIG=%ROOT%\config\mysql.conf

REM =====================================
REM READ CONFIG
REM =====================================

for /f "tokens=1,2 delims==" %%A in (%CONFIG%) do (
    if "%%A"=="MYSQL_PORT" set MYSQL_PORT=%%B
    if "%%A"=="MYSQL_DB" set MYSQL_DB=%%B
    if "%%A"=="MYSQL_USER" set MYSQL_USER=%%B
    if "%%A"=="MYSQL_PASSWORD" set MYSQL_PASSWORD=%%B
)

REM =====================================
REM MYSQL PATH
REM =====================================

set MYSQL_EXE=%ROOT%\databases\mysql\server\bin\mysql.exe

echo.
echo =====================================
echo DATABASE CHECK
echo =====================================
echo.

echo Creating database if not exists...

"%MYSQL_EXE%" ^
-u %MYSQL_USER% ^
-P %MYSQL_PORT% ^
-e "CREATE DATABASE IF NOT EXISTS %MYSQL_DB%;"

if errorlevel 1 (
    echo Database creation failed.
    pause
    exit /b 1
)

echo Database Ready : %MYSQL_DB%

pause