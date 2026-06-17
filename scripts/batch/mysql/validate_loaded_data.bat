@echo off
setlocal

echo.
echo =====================================
echo VALIDATING LOADED DATA
echo =====================================
echo.

python scripts\python\mysql\validate_loaded_data.py

if errorlevel 1 (
    echo.
    echo LOADED DATA VALIDATION FAILED
    exit /b 1
)

echo.
echo LOADED DATA VALIDATION SUCCESSFUL
echo.

exit /b 0