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
echo MYSQL AUTOMATION PIPELINE
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

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\validate_python_requirements.bat"

if errorlevel 1 (
    echo ERROR: PYTHON REQUIREMENTS VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM START MYSQL
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\start_mysql.bat"

if errorlevel 1 (
    echo ERROR: MYSQL START FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE MYSQL
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\validate_mysql.bat"

if errorlevel 1 (
    echo ERROR: MYSQL VALIDATION FAILED
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

call "%PROJECT_ROOT%\scripts\batch\mysql\load\load_data.bat"

if errorlevel 1 (
    echo ERROR: DATA LOAD FAILED
    exit /b 1
)


REM =====================================
REM DEPLOY DATABASE OBJECTS
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mysql\objects\deploy_objects.bat"

if errorlevel 1 (
    echo ERROR: DATABASE OBJECT DEPLOYMENT FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE DATABASE OBJECTS
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mysql\objects\validate_objects.bat"

if errorlevel 1 (
    echo ERROR: DATABASE OBJECT VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM DATABASE ASSESSMENT
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mysql\assessment\run_assessment.bat" all

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
echo MYSQL AUTOMATION PIPELINE SUCCESSFUL
echo =====================================
echo.

exit /b 0