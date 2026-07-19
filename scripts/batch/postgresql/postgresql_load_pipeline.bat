@echo off
setlocal EnableDelayedExpansion

REM =====================================
REM PROJECT ROOT
REM =====================================

call "%~dp0..\common\set_project_root.bat"

if errorlevel 1 (
    echo ERROR: PROJECT ROOT SETUP FAILED
    exit /b 1
)

cd /d "%PROJECT_ROOT%"


echo.
echo =====================================
echo POSTGRESQL AUTOMATION PIPELINE
echo =====================================
echo.


REM =====================================
REM VALIDATE PYTHON RUNTIME
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"

if errorlevel 1 (
    echo ERROR: PYTHON RUNTIME VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE PYTHON REQUIREMENTS
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\validate_python_requirements.bat"

if errorlevel 1 (
    echo ERROR: PYTHON REQUIREMENTS VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM START POSTGRESQL
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\start_postgresql.bat"

if errorlevel 1 (
    echo ERROR: POSTGRESQL START FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE POSTGRESQL
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\validate_postgresql.bat"

if errorlevel 1 (
    echo ERROR: POSTGRESQL VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM DOWNLOAD DATASET
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\common\download_dataset.bat"

if errorlevel 1 (
    echo ERROR: DATASET DOWNLOAD FAILED
    exit /b 1
)


REM =====================================
REM LOAD DATA
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\load\load_data.bat"

if errorlevel 1 (
    echo ERROR: DATA LOAD FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE LOADED DATA
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\load\validate_loaded_data.bat"

if errorlevel 1 (
    echo ERROR: LOADED DATA VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM DEPLOY DATABASE OBJECTS
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\objects\deploy_objects.bat"

if errorlevel 1 (
    echo ERROR: DATABASE OBJECT DEPLOYMENT FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE DATABASE OBJECTS
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\objects\validate_objects.bat"

if errorlevel 1 (
    echo ERROR: DATABASE OBJECT VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM DATABASE ASSESSMENT
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\assessment\run_assessment.bat" all

if errorlevel 1 (
    echo ERROR: DATABASE ASSESSMENT FAILED
    exit /b 1
)


REM =====================================
REM GENERATE ASSESSMENT REPORT
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\common\generate_assessment_report.bat"

if errorlevel 1 (
    echo ERROR: ASSESSMENT REPORT GENERATION FAILED
    exit /b 1
)


echo.
echo =====================================
echo POSTGRESQL AUTOMATION PIPELINE SUCCESSFUL
echo =====================================
echo.

exit /b 0
