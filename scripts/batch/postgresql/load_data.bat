@echo off
setlocal

echo ===================================
echo LOAD DATA INTO POSTGRESQL
echo ===================================

python "%~dp0..\..\python\postgresql\load_all.py"

if errorlevel 1 (
    echo FAILED: Data load failed
    exit /b 1
)

echo.
echo ===================================
echo DATA LOAD SUCCESSFUL
echo ===================================

exit /b 0