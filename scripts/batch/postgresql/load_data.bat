@echo off
setlocal

echo ===================================
echo LOAD DATA INTO POSTGRESQL
echo ===================================

echo Generating datasets...
python "%~dp0..\..\python\postgresql\generate_dataset.py"
if errorlevel 1 (
    echo WARNING: Dataset generation had issues
)

echo.
echo Loading all data...
python "%~dp0..\..\python\postgresql\load_all.py"

if errorlevel 1 (
    echo FAILED: Data load failed
    exit /b 1
)

echo.
echo Data Load Completed Successfully

exit /b 0
