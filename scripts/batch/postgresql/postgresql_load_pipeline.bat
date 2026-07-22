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
REM PROFILE SOURCE DATA
REM =====================================

python scripts\profiling\data_profiler.py --database postgresql

if errorlevel 1 (
    echo ERROR: DATA PROFILING FAILED
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


REM =====================================
REM DATABASE ASSESSMENT
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\postgresql\assessment\run_assessment.bat" all

if errorlevel 1 (
    echo ERROR: DATABASE ASSESSMENT FAILED
    exit /b 1
)


REM =====================================
REM ASSESSMENT REPORT
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\common\generate_assessment_report.bat"

if errorlevel 1 (
    echo ERROR: ASSESSMENT REPORT GENERATION FAILED
    exit /b 1
)


REM =====================================
REM RECONCILE SOURCE AND TARGET DATA
REM =====================================

python scripts\reconciliation\reconciliation_engine.py --database postgresql

if errorlevel 1 (
    echo ERROR: RECONCILIATION FAILED
    exit /b 1
)


REM =====================================
REM DISCOVER DATABASE ENVIRONMENT
REM =====================================

python scripts\discovery\discovery_engine.py --database postgresql

if errorlevel 1 (
    echo ERROR: DISCOVERY FAILED
    exit /b 1
)


REM =====================================
REM ANALYZE DATABASE GROWTH
REM =====================================

python scripts\discovery\growth_analyzer.py --database postgresql

if errorlevel 1 (
    echo ERROR: GROWTH ANALYSIS FAILED
    exit /b 1
)


REM =====================================
REM ANALYZE MIGRATION REQUIREMENTS
REM =====================================

python scripts\discovery\requirement_analyzer.py --database postgresql

if errorlevel 1 (
    echo ERROR: REQUIREMENT ANALYSIS FAILED
    exit /b 1
)


REM =====================================
REM ASSESS MIGRATION
REM =====================================

python scripts\assessment\assessment_engine.py --database postgresql

if errorlevel 1 (
    echo ERROR: MIGRATION ASSESSMENT FAILED
    exit /b 1
)


REM =====================================
REM GENERATE MIGRATION RECOMMENDATIONS
REM =====================================

python scripts\recommendation\recommendation_engine.py --database postgresql

if errorlevel 1 (
    echo ERROR: RECOMMENDATION GENERATION FAILED
    exit /b 1
)


REM =====================================
REM GENERATE GOVERNANCE ACTION PLAN
REM =====================================

python scripts\governance\action_plan_engine.py --database postgresql

if errorlevel 1 (
    echo ERROR: ACTION PLAN GENERATION FAILED
    exit /b 1
)


REM =====================================
REM GENERATE TECHNICAL MIGRATION REPORT
REM =====================================

python scripts\reporting\migration\technical_report.py --database postgresql

if errorlevel 1 (
    echo ERROR: TECHNICAL REPORT GENERATION FAILED
    exit /b 1
)


REM =====================================
REM GENERATE EXECUTIVE MIGRATION REPORT
REM =====================================

python scripts\reporting\migration\executive_report.py --database postgresql

if errorlevel 1 (
    echo ERROR: EXECUTIVE REPORT GENERATION FAILED
    exit /b 1
)


echo.
echo =====================================
echo POSTGRESQL AUTOMATION PIPELINE SUCCESSFUL
echo =====================================
echo.

exit /b 0