@echo off
setlocal

echo ===================================
echo CREATE POSTGRESQL DATABASE
echo ===================================

python "%~dp0..\..\python\postgresql\create_database.py"

if errorlevel 1 (
    echo FAILED: Database creation failed
    exit /b 1
)

echo Database creation completed successfully

exit /b 0
