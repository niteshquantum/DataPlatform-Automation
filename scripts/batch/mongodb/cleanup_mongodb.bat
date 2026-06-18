@echo off

echo ===================================
echo Cleaning MongoDB Collections
echo ===================================

python "%~dp0..\..\python\mongodb\cleanup_collections.py"

if errorlevel 1 (
    echo MongoDB Cleanup Failed
    exit /b 1
)

echo MongoDB Cleanup Successful