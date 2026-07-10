@echo off
setlocal

echo.
echo =====================================
echo STOPPING POSTGRESQL FOR CLEANUP
echo =====================================
echo.

REM =====================================
REM PROJECT ROOT
REM =====================================

call "%~dp0..\..\common\set_project_root.bat"

if errorlevel 1 (
    echo ERROR: Unable to determine project root.
    exit /b 1
)

set "ROOT=%PROJECT_ROOT%"

set "STOP_SCRIPT=%ROOT%\scripts\powershell\postgresql\cleanup\stop_postgresql.ps1"

REM =====================================
REM CHECK POWERSHELL SCRIPT
REM =====================================

if not exist "%STOP_SCRIPT%" (
    echo ERROR: PostgreSQL cleanup stop script not found:
    echo %STOP_SCRIPT%
    exit /b 1
)

REM =====================================
REM STOP POSTGRESQL
REM =====================================

powershell.exe ^
-NoProfile ^
-NonInteractive ^
-ExecutionPolicy Bypass ^
-File "%STOP_SCRIPT%"

if errorlevel 1 (
    echo ERROR: PostgreSQL cleanup stop failed.
    exit /b 1
)

echo.
echo =====================================
echo POSTGRESQL STOP COMPLETED
echo =====================================
echo.

exit /b 0