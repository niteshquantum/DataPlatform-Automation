@echo off

echo.
echo =====================================
echo VALIDATING CSV FILES
echo =====================================
echo.

py scripts\python\mysql\validate_csv.py

if errorlevel 1 (
    echo.
    echo CSV VALIDATION FAILED
    exit /b 1
)

echo.
echo CSV VALIDATION SUCCESSFUL
echo.