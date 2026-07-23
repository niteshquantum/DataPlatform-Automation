@echo off
setlocal EnableDelayedExpansion

REM =====================================
REM PROJECT ROOT
REM =====================================

call "%~dp0..\..\common\set_project_root.bat"

if errorlevel 1 (
    echo ERROR: PROJECT ROOT SETUP FAILED
    exit /b 1
)

cd /d "%PROJECT_ROOT%"

set "PYTHONPATH=%PROJECT_ROOT%;%PYTHONPATH%"


echo.
echo =====================================
echo POSTGRESQL DATABASE OBJECT AUTOMATION
echo =====================================
echo.

REM =====================================
REM GENERATE DATABASE OBJECTS
REM =====================================

echo.
echo -------------------------------------
echo GENERATING DATABASE OBJECTS
echo -------------------------------------
echo.

python scripts\python\common\objects\bootstrap_generator.py postgresql

if errorlevel 1 (
    echo ERROR: DATABASE OBJECT GENERATION FAILED
    exit /b 1
)


REM =====================================
REM DEPLOY DATABASE OBJECTS
REM =====================================

echo.
echo -------------------------------------
echo DEPLOYING DATABASE OBJECTS
echo -------------------------------------
echo.

REM Clear checksums so regenerated object changelogs do not trigger
REM ValidationFailedException when they were already deployed earlier
REM via master.xml (which includes master_objects.xml).
call "%ROOT%\scripts\batch\postgresql\setup\run_liquibase.bat" "liquibase\postgresql\master_objects.xml" clearCheckSums

if errorlevel 1 (
    echo ERROR: LIQUIBASE CHECKSUM CLEAR FAILED
    exit /b 1
)

python scripts\python\common\objects\deploy_objects.py postgresql

if errorlevel 1 (
    echo ERROR: POSTGRESQL OBJECTS DEPLOYMENT FAILED
    exit /b 1
)


echo.
echo =====================================
echo POSTGRESQL OBJECT AUTOMATION SUCCESSFUL
echo =====================================
echo.

exit /b 0
