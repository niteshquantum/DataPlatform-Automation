@echo off
REM ============================================================
REM load_postgresql.bat
REM Batch equivalent of Jenkinsfile: PostgreSQL load pipeline
REM Original stages preserved 1:1, linear sequence
REM ============================================================

setlocal EnableDelayedExpansion

set "BASE=scripts\batch"

REM ------------------------------------------------------------
REM STAGE: Validate Python Runtime
REM ------------------------------------------------------------
echo ============================================
echo STAGE: Validate Python Runtime
echo ============================================
call "%BASE%\common\validate_python_runtime.bat"
if %ERRORLEVEL% NEQ 0 goto :fail

REM ------------------------------------------------------------
REM STAGE: Validate Python Requirements
REM ------------------------------------------------------------
echo ============================================
echo STAGE: Validate Python Requirements
echo ============================================
call "%BASE%\postgresql\setup\validate_python_requirements.bat"
if %ERRORLEVEL% NEQ 0 goto :fail

REM ------------------------------------------------------------
REM STAGE: Start PostgreSQL Service
REM ------------------------------------------------------------
echo ============================================
echo STAGE: Start PostgreSQL Service
echo ============================================
call "%BASE%\postgresql\setup\start_postgresql.bat"
if %ERRORLEVEL% NEQ 0 goto :fail

REM ------------------------------------------------------------
REM STAGE: Validate PostgreSQL
REM ------------------------------------------------------------
echo ============================================
echo STAGE: Validate PostgreSQL
echo ============================================
call "%BASE%\postgresql\setup\validate_postgresql.bat"
if %ERRORLEVEL% NEQ 0 goto :fail

REM ------------------------------------------------------------
REM STAGE: Download Dataset
REM ------------------------------------------------------------
echo ============================================
echo STAGE: Download Dataset
echo ============================================
call "%BASE%\common\download_dataset.bat"
if %ERRORLEVEL% NEQ 0 goto :fail

REM ------------------------------------------------------------
REM STAGE: Load Data
REM ------------------------------------------------------------
echo ============================================
echo STAGE: Load Data
echo ============================================
call "%BASE%\postgresql\load\load_data.bat"
if %ERRORLEVEL% NEQ 0 goto :fail

REM ------------------------------------------------------------
REM STAGE: Validate Loaded Data
REM ------------------------------------------------------------
echo ============================================
echo STAGE: Validate Loaded Data
echo ============================================
call "%BASE%\postgresql\load\validate_loaded_data.bat"
if %ERRORLEVEL% NEQ 0 goto :fail

REM ==============================================================
REM post { success { ... } }
REM ==============================================================
:success
echo.
echo POSTGRESQL LOAD SUCCESSFUL
echo POSTGRESQL LOAD PIPELINE COMPLETED
endlocal
exit /b 0

REM ==============================================================
REM post { failure { ... } }
REM ==============================================================
:fail
echo.
echo POSTGRESQL LOAD FAILED
echo POSTGRESQL LOAD PIPELINE COMPLETED
endlocal
exit /b 1