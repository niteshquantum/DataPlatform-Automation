@echo off
setlocal

echo.
echo =====================================
echo POSTGRESQL WINDOWS CLEANUP PIPELINE
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

REM =====================================
REM CLEANUP MODE
REM =====================================

if "%CLEANUP_MODE%"=="" (
    set "CLEANUP_MODE=PRESERVE_DATA"
)

if /I not "%CLEANUP_MODE%"=="PRESERVE_DATA" (
    if /I not "%CLEANUP_MODE%"=="DELETE_DATA" (
        echo ERROR: Invalid cleanup mode: %CLEANUP_MODE%
        echo Valid modes: PRESERVE_DATA or DELETE_DATA
        exit /b 1
    )
)

echo Project Root : %ROOT%
echo Cleanup Mode : %CLEANUP_MODE%
echo.

REM =====================================
REM POWERSHELL CLEANUP DIRECTORY
REM =====================================

set "CLEANUP_DIR=%ROOT%\scripts\powershell\postgresql\cleanup"

REM =====================================
REM VALIDATE CLEANUP SCRIPTS
REM =====================================

if not exist "%CLEANUP_DIR%\stop_postgresql.ps1" (
    echo ERROR: stop_postgresql.ps1 not found
    exit /b 1
)

if not exist "%CLEANUP_DIR%\remove_postgresql.ps1" (
    echo ERROR: remove_postgresql.ps1 not found
    exit /b 1
)

if not exist "%CLEANUP_DIR%\reset_terraform_state.ps1" (
    echo ERROR: reset_terraform_state.ps1 not found
    exit /b 1
)

if not exist "%CLEANUP_DIR%\cleanup_postgresql_load_artifacts.ps1" (
    echo ERROR: cleanup_postgresql_load_artifacts.ps1 not found
    exit /b 1
)

if not exist "%CLEANUP_DIR%\cleanup_postgresql_xml.ps1" (
    echo ERROR: cleanup_postgresql_xml.ps1 not found
    exit /b 1
)

if not exist "%CLEANUP_DIR%\validate_cleanup.ps1" (
    echo ERROR: validate_cleanup.ps1 not found
    exit /b 1
)

echo All PostgreSQL cleanup scripts validated successfully.
echo.

REM =====================================
REM STEP 1 - STOP POSTGRESQL
REM =====================================

echo =====================================
echo STEP 1 - STOP POSTGRESQL
echo =====================================

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
-File "%CLEANUP_DIR%\stop_postgresql.ps1"

if errorlevel 1 (
    echo ERROR: PostgreSQL stop stage failed.
    exit /b 1
)

REM =====================================
REM STEP 2 - REMOVE POSTGRESQL
REM =====================================

echo.
echo =====================================
echo STEP 2 - REMOVE POSTGRESQL
echo =====================================

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
-File "%CLEANUP_DIR%\remove_postgresql.ps1" ^
-CleanupMode "%CLEANUP_MODE%"

if errorlevel 1 (
    echo ERROR: PostgreSQL removal stage failed.
    exit /b 1
)

REM =====================================
REM STEP 3 - RESET TERRAFORM STATE
REM =====================================

echo.
echo =====================================
echo STEP 3 - RESET TERRAFORM STATE
echo =====================================

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
-File "%CLEANUP_DIR%\reset_terraform_state.ps1"

if errorlevel 1 (
    echo ERROR: PostgreSQL Terraform reset stage failed.
    exit /b 1
)

REM =====================================
REM STEP 4 - CLEAN LOAD ARTIFACTS
REM =====================================

echo.
echo =====================================
echo STEP 4 - CLEAN LOAD ARTIFACTS
echo =====================================

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
-File "%CLEANUP_DIR%\cleanup_postgresql_load_artifacts.ps1"

if errorlevel 1 (
    echo ERROR: PostgreSQL load artifacts cleanup failed.
    exit /b 1
)

REM =====================================
REM STEP 5 - CLEAN XML ARTIFACTS
REM =====================================

echo.
echo =====================================
echo STEP 5 - CLEAN XML ARTIFACTS
echo =====================================

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
-File "%CLEANUP_DIR%\cleanup_postgresql_xml.ps1"

if errorlevel 1 (
    echo ERROR: PostgreSQL XML cleanup failed.
    exit /b 1
)

REM =====================================
REM STEP 6 - VALIDATE CLEANUP
REM =====================================

echo.
echo =====================================
echo STEP 6 - VALIDATE CLEANUP
echo =====================================

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
-File "%CLEANUP_DIR%\validate_cleanup.ps1" ^
-CleanupMode "%CLEANUP_MODE%"

if errorlevel 1 (
    echo ERROR: PostgreSQL cleanup validation failed.
    exit /b 1
)

REM =====================================
REM SUCCESS
REM =====================================

echo.
echo =====================================
echo POSTGRESQL CLEANUP PIPELINE COMPLETED
echo =====================================
echo.
echo Project Root : %ROOT%
echo Cleanup Mode : %CLEANUP_MODE%
echo Status       : SUCCESS
echo.

exit /b 0
