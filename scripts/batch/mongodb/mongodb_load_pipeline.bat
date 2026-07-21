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
echo MONGODB AUTOMATION PIPELINE
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

call "%PROJECT_ROOT%\scripts\batch\mongodb\setup\validate_python_requirements.bat"

if errorlevel 1 (
    echo ERROR: PYTHON REQUIREMENTS VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM START MONGODB
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mongodb\setup\start_mongodb.bat"

if errorlevel 1 (
    echo ERROR: MONGODB START FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE MONGODB
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mongodb\setup\validate_mongodb.bat"

if errorlevel 1 (
    echo ERROR: MONGODB VALIDATION FAILED
    exit /b 1
)


REM =====================================
REM LOAD DATA
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mongodb\load\load_data.bat"

if errorlevel 1 (
    echo ERROR: DATA LOAD FAILED
    exit /b 1
)


REM =====================================
REM VALIDATE LOADED DATA
REM =====================================

call "%PROJECT_ROOT%\scripts\batch\mongodb\load\validate_loaded_data.bat"

if errorlevel 1 (
    echo ERROR: LOADED DATA VALIDATION FAILED
    exit /b 1
)


@REM ============================================================
@REM OPTIONAL POST-PROCESSING
@REM Assessment/reporting is intentionally not part of CORE LOAD.
@REM Execute through dedicated assessment/reporting entry point.
@REM ============================================================

@REM call "%PROJECT_ROOT%\scripts\batch\mongodb\assessment\run_assessment.bat" all

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
echo MONGODB AUTOMATION PIPELINE SUCCESSFUL
echo =====================================
echo.

exit /b 0