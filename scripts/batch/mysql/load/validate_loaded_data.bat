@echo off
setlocal

echo.
echo =====================================
echo VALIDATING LOADED DATA
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"
if errorlevel 1 exit /b 1

set "PYTHONPATH=%PROJECT_ROOT%;%PYTHONPATH%"

cd /d "%PROJECT_ROOT%"

python scripts\python\mysql\load\validate_loaded_data.py

if errorlevel 1 (
    echo.
    echo LOADED DATA VALIDATION FAILED
    exit /b 1
)

echo.
echo LOADED DATA VALIDATION SUCCESSFUL
echo.

exit /b 0
