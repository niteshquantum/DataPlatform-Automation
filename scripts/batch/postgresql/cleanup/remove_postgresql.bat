@echo off
setlocal

echo.
echo =====================================
echo REMOVING POSTGRESQL DEPLOYMENT
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

set "REMOVE_SCRIPT=%ROOT%\scripts\powershell\postgresql\cleanup\remove_postgresql.ps1"

REM =====================================
REM CLEANUP MODE
REM =====================================

set "CLEANUP_MODE=%~1"

if "%CLEANUP_MODE%"=="" (
    set "CLEANUP_MODE=PRESERVE_DATA"
)

if /I not "%CLEANUP_MODE%"=="PRESERVE_DATA" (
    if /I not "%CLEANUP_MODE%"=="DELETE_DATA" (
        echo ERROR: Invalid cleanup mode: %CLEANUP_MODE%
        echo.
        echo Valid cleanup modes:
        echo   PRESERVE_DATA
        echo   DELETE_DATA
        exit /b 1
    )
)

echo Cleanup Mode: %CLEANUP_MODE%
echo.

REM =====================================
REM CHECK POWERSHELL SCRIPT
REM =====================================

if not exist "%REMOVE_SCRIPT%" (
    echo ERROR: PostgreSQL removal script not found:
    echo %REMOVE_SCRIPT%
    exit /b 1
)

REM =====================================
REM REMOVE POSTGRESQL DEPLOYMENT
REM =====================================

powershell.exe ^
-NoProfile ^
-NonInteractive ^
-ExecutionPolicy Bypass ^
-File "%REMOVE_SCRIPT%" ^
-CleanupMode "%CLEANUP_MODE%"

if errorlevel 1 (
    echo ERROR: PostgreSQL deployment removal failed.
    exit /b 1
)

echo.
echo =====================================
echo POSTGRESQL REMOVAL COMPLETED
echo =====================================
echo.
echo Cleanup Mode: %CLEANUP_MODE%
echo.

exit /b 0