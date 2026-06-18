@echo off

echo ===================================
echo Validating MongoDB Port
echo ===================================

python "%~dp0..\..\python\mongodb\validate_port.py"

if errorlevel 1 (
    echo MongoDB Port Validation Failed
    exit /b 1
)

echo MongoDB Port Validation Successful