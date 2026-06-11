@echo off

echo.
echo =====================================
echo VALIDATING MYSQL PORT
echo =====================================
echo.

py scripts\python\mysql\validate_port.py

if errorlevel 1 (
    echo.
    echo PORT VALIDATION FAILED
    exit /b 1
)

echo.
echo PORT VALIDATION SUCCESSFUL
echo.