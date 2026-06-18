@echo off

echo ===================================
echo Validating MongoDB
echo ===================================

python "%~dp0..\..\python\mongodb\validate_mongodb.py"

if errorlevel 1 (
    echo MongoDB Validation Failed
    exit /b 1
)

echo MongoDB Validation Successful