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

set "XML_CLEANUP_SCRIPT=%ROOT%\scripts\batch\postgresql\cleanup\cleanup_postgresql_xml.bat"

set "LOAD_ARTIFACTS_SCRIPT=%ROOT%\scripts\batch\postgresql\cleanup\cleanup_postgresql_load_artifacts.bat"

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
if not exist "%XML_CLEANUP_SCRIPT%" (
    echo ERROR: PostgreSQL XML cleanup script not found:
    echo %XML_CLEANUP_SCRIPT%
    exit /b 1
)

if not exist "%LOAD_ARTIFACTS_SCRIPT%" (
    echo ERROR: PostgreSQL load artifacts cleanup script not found:
    echo %LOAD_ARTIFACTS_SCRIPT%
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
REM STEP 4 - CLEANUP LIQUIBASE XML
REM =====================================

echo =====================================
echo STEP 4 - CLEANUP LIQUIBASE XML
echo =====================================
echo.

call "%XML_CLEANUP_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: PostgreSQL Liquibase XML cleanup stage failed.
    exit /b 1
)

echo.
echo PostgreSQL Liquibase XML cleanup completed successfully.
echo.

REM =====================================
REM STEP 5 - CLEANUP LOAD ARTIFACTS
REM =====================================

echo =====================================
echo STEP 5 - CLEANUP LOAD ARTIFACTS
echo =====================================
echo.

call "%LOAD_ARTIFACTS_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: PostgreSQL load artifacts cleanup stage failed.
    exit /b 1
)

echo.
echo PostgreSQL load artifacts cleanup completed successfully.
echo.

REM =====================================
REM STEP 6 - VALIDATE CLEANUP
REM =====================================

echo =====================================
echo STEP 6 - VALIDATE CLEANUP
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