@echo off
setlocal

echo.
echo =====================================
echo POSTGRESQL CLEANUP PIPELINE
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
        echo.
        echo Valid cleanup modes:
        echo   PRESERVE_DATA
        echo   DELETE_DATA
        exit /b 1
    )
)

echo Project Root : %ROOT%
echo Cleanup Mode : %CLEANUP_MODE%
echo.

REM =====================================
REM CLEANUP SCRIPT PATHS
REM =====================================

set "STOP_SCRIPT=%ROOT%\scripts\batch\postgresql\cleanup\stop_postgresql.bat"

set "REMOVE_SCRIPT=%ROOT%\scripts\batch\postgresql\cleanup\remove_postgresql.bat"

set "RESET_TERRAFORM_SCRIPT=%ROOT%\scripts\batch\postgresql\cleanup\reset_terraform_state.bat"

set "VALIDATE_SCRIPT=%ROOT%\scripts\batch\postgresql\cleanup\validate_cleanup.bat"

REM =====================================
REM VALIDATE CLEANUP SCRIPTS
REM =====================================

echo =====================================
echo VALIDATING CLEANUP SCRIPTS
echo =====================================
echo.

if not exist "%STOP_SCRIPT%" (
    echo ERROR: Stop script not found:
    echo %STOP_SCRIPT%
    exit /b 1
)

if not exist "%REMOVE_SCRIPT%" (
    echo ERROR: Remove script not found:
    echo %REMOVE_SCRIPT%
    exit /b 1
)

if not exist "%RESET_TERRAFORM_SCRIPT%" (
    echo ERROR: Terraform reset script not found:
    echo %RESET_TERRAFORM_SCRIPT%
    exit /b 1
)

if not exist "%VALIDATE_SCRIPT%" (
    echo ERROR: Validation script not found:
    echo %VALIDATE_SCRIPT%
    exit /b 1
)

echo All PostgreSQL cleanup scripts found successfully.
echo.

REM =====================================
REM STEP 1 - STOP POSTGRESQL
REM =====================================

echo =====================================
echo STEP 1 - STOP POSTGRESQL
echo =====================================
echo.

call "%STOP_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: PostgreSQL stop stage failed.
    exit /b 1
)

echo.
echo PostgreSQL stop stage completed successfully.
echo.

REM =====================================
REM STEP 2 - REMOVE POSTGRESQL
REM =====================================

echo =====================================
echo STEP 2 - REMOVE POSTGRESQL DEPLOYMENT
echo =====================================
echo.

call "%REMOVE_SCRIPT%" "%CLEANUP_MODE%"

if errorlevel 1 (
    echo.
    echo ERROR: PostgreSQL removal stage failed.
    exit /b 1
)

echo.
echo PostgreSQL removal stage completed successfully.
echo.

REM =====================================
REM STEP 3 - RESET TERRAFORM STATE
REM =====================================

echo =====================================
echo STEP 3 - RESET TERRAFORM STATE
echo =====================================
echo.

call "%RESET_TERRAFORM_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: PostgreSQL Terraform reset stage failed.
    exit /b 1
)

echo.
echo PostgreSQL Terraform reset stage completed successfully.
echo.

REM =====================================
REM STEP 4 - VALIDATE CLEANUP
REM =====================================

echo =====================================
echo STEP 4 - VALIDATE CLEANUP
echo =====================================
echo.

call "%VALIDATE_SCRIPT%" "%CLEANUP_MODE%"

if errorlevel 1 (
    echo.
    echo ERROR: PostgreSQL cleanup validation stage failed.
    exit /b 1
)

echo.
echo PostgreSQL cleanup validation completed successfully.
echo.

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