@echo off

echo ===================================
echo Loading MongoDB Data
echo ===================================

python "%~dp0..\..\python\mongodb\load_all.py"

if errorlevel 1 (
    echo Data Load Failed
    exit /b 1
)

echo Data Load Completed Successfully