@echo off

echo ===================================
echo Validating MongoDB Data
echo ===================================

python "%~dp0..\..\python\mongodb\validate_data.py"

if errorlevel 1 (
    echo MongoDB Data Validation Failed
    exit /b 1
)

echo MongoDB Data Validation Successful