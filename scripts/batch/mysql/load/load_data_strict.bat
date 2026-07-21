@echo off
setlocal

call "%~dp0..\..\common\set_project_root.bat"
if errorlevel 1 exit /b 1

cd /d "%PROJECT_ROOT%"
set "PYTHONPATH=%PROJECT_ROOT%;%PYTHONPATH%"
set "LOAD_MODE=%LOAD_MODE%"
if "%LOAD_MODE%"=="" set "LOAD_MODE=skip"

set "STRICT_SCHEMA=true"

echo.
echo -------------------------------------
echo LOADING DATA (STRICT MODE)
echo -------------------------------------
echo.

echo LOAD MODE : %LOAD_MODE%

python scripts\data_loader.py mysql
if errorlevel 1 exit /b 1

echo.
echo -------------------------------------
echo VALIDATING LOADED DATA
echo -------------------------------------
echo.

python scripts\python\mysql\load\validate_loaded_data.py
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo DATA LOAD SUCCESSFUL
echo =====================================
echo.

exit /b 0
