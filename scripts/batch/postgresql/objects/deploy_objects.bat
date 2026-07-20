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
python scripts\python\common\check_schema_changed.py postgresql

if errorlevel 2 (
    echo.
    echo =====================================
    echo NO SCHEMA CHANGES DETECTED
    echo SKIPPING DATABASE OBJECT DEPLOYMENT
    echo =====================================
    echo.
    exit /b 0
)

if errorlevel 1 (
    echo ERROR: Unable to read CDC status.
    exit /b 1
)

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
