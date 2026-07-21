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
REM CREATE DATABASE
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\create_database.bat"

if errorlevel 1 (
    echo ERROR: DATABASE CREATION FAILED
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
REM CDC CHECK
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\load\run_cdc.bat"

if errorlevel 100 (
    echo.
    echo SKIPPING DATA LOAD — NO CDC CHANGES
    echo.
    goto :skip_data_load
)

if errorlevel 1 (
    echo ERROR: CDC CHECK FAILED
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

:skip_data_load


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


@REM ============================================================
@REM OPTIONAL POST-PROCESSING
@REM Assessment/reporting is intentionally not part of CORE LOAD.
@REM Execute through dedicated assessment/reporting entry point.
@REM ============================================================

@REM call "%PROJECT_ROOT%\scripts\batch\postgresql\assessment\run_assessment.bat" all

@REM if errorlevel 1 (
@REM     echo ERROR: DATABASE ASSESSMENT FAILED
@REM     exit /b 1
@REM )


@REM REM ============================================================
@REM OPTIONAL POST-PROCESSING
@REM Assessment/reporting is intentionally not part of CORE LOAD.
@REM Execute through dedicated assessment/reporting entry point.
@REM ============================================================

@REM call "%PROJECT_ROOT%\scripts\batch\common\generate_assessment_report.bat"

@REM if errorlevel 1 (
@REM     echo ERROR: ASSESSMENT REPORT GENERATION FAILED
@REM     exit /b 1
@REM )


echo.
echo =====================================
echo POSTGRESQL AUTOMATION PIPELINE SUCCESSFUL
echo =====================================
echo.

exit /b 0
