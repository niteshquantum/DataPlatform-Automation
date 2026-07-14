@echo off
setlocal

echo.
echo =====================================
echo MSSQL CLEANUP PIPELINE
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

set "STOP_SCRIPT=%ROOT%\scripts\batch\mssql\cleanup\stop_mssql.bat"

set "DROP_DATABASE_SCRIPT=%ROOT%\scripts\batch\mssql\cleanup\drop_mssql_database.bat"

set "REMOVE_SCRIPT=%ROOT%\scripts\batch\mssql\cleanup\remove_mssql.bat"

set "RESET_TERRAFORM_SCRIPT=%ROOT%\scripts\batch\mssql\cleanup\reset_terraform_state.bat"

set "XML_CLEANUP_SCRIPT=%ROOT%\scripts\batch\mssql\cleanup\cleanup_mssql_xml.bat"

set "LOAD_ARTIFACTS_SCRIPT=%ROOT%\scripts\batch\mssql\cleanup\cleanup_mssql_load_artifacts.bat"

set "VALIDATE_SCRIPT=%ROOT%\scripts\batch\mssql\cleanup\validate_cleanup.bat"

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

if not exist "%DROP_DATABASE_SCRIPT%" (
    echo ERROR: Database cleanup script not found:
    echo %DROP_DATABASE_SCRIPT%
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
    echo ERROR: MSSQL XML cleanup script not found:
    echo %XML_CLEANUP_SCRIPT%
    exit /b 1
)

if not exist "%LOAD_ARTIFACTS_SCRIPT%" (
    echo ERROR: MSSQL load artifacts cleanup script not found:
    echo %LOAD_ARTIFACTS_SCRIPT%
    exit /b 1
)

if not exist "%VALIDATE_SCRIPT%" (
    echo ERROR: Validation script not found:
    echo %VALIDATE_SCRIPT%
    exit /b 1
)

echo All MSSQL cleanup scripts found successfully.
echo.

REM =====================================
REM STEP 1 - DROP DATABASE BEFORE STOPPING MSSQL
REM =====================================

echo =====================================
echo STEP 1 - DROP DATABASE
echo =====================================
echo.

call "%DROP_DATABASE_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL database cleanup stage failed.
    exit /b 1
)

echo.
echo MSSQL database cleanup stage completed successfully.
echo.

REM =====================================
REM STEP 2 - STOP MSSQL
REM =====================================

echo =====================================
echo STEP 2 - STOP MSSQL
echo =====================================
echo.

call "%STOP_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL stop stage failed.
    exit /b 1
)

echo.
echo MSSQL stop stage completed successfully.
echo.

REM =====================================
REM STEP 3 - REMOVE MSSQL
REM =====================================

echo =====================================
echo STEP 3 - REMOVE MSSQL DEPLOYMENT
echo =====================================
echo.

call "%REMOVE_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL removal stage failed.
    exit /b 1
)

echo.
echo MSSQL removal stage completed successfully.
echo.

REM =====================================
REM STEP 4 - RESET TERRAFORM STATE
REM =====================================

echo =====================================
echo STEP 4 - RESET TERRAFORM STATE
echo =====================================
echo.

call "%RESET_TERRAFORM_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL Terraform reset stage failed.
    exit /b 1
)

echo.
echo MSSQL Terraform reset stage completed successfully.
echo.

REM =====================================
REM STEP 5 - CLEANUP LIQUIBASE XML
REM =====================================

echo =====================================
echo STEP 5 - CLEANUP LIQUIBASE XML
echo =====================================
echo.

call "%XML_CLEANUP_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL Liquibase XML cleanup stage failed.
    exit /b 1
)

echo.
echo MSSQL Liquibase XML cleanup completed successfully.
echo.

REM =====================================
REM STEP 6 - CLEANUP LOAD ARTIFACTS
REM =====================================

echo =====================================
echo STEP 6 - CLEANUP LOAD ARTIFACTS
echo =====================================
echo.

call "%LOAD_ARTIFACTS_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL load artifacts cleanup stage failed.
    exit /b 1
)

echo.
echo MSSQL load artifacts cleanup completed successfully.
echo.

REM =====================================
REM STEP 7 - VALIDATE CLEANUP
REM =====================================

echo =====================================
echo STEP 7 - VALIDATE CLEANUP
echo =====================================
echo.

call "%VALIDATE_SCRIPT%"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL cleanup validation stage failed.
    exit /b 1
)

echo.
echo MSSQL cleanup validation completed successfully.
echo.

REM =====================================
REM SUCCESS
REM =====================================

echo.
echo =====================================
echo MSSQL CLEANUP PIPELINE COMPLETED
echo =====================================
echo.

echo Project Root : %ROOT%
echo Cleanup Mode : %CLEANUP_MODE%
echo Status       : SUCCESS
echo.

exit /b 0
