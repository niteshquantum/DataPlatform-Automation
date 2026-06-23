@echo off
setlocal

echo ============================================
echo ENVIRONMENT VALIDATION
echo ============================================

echo.
echo --- Python ---
python --version
if errorlevel 1 (
    echo FAIL: Python not found
    exit /b 1
)

echo.
echo --- Java ---
java -version 2>&1
if errorlevel 1 (
    echo FAIL: Java not found
    exit /b 1
)

echo.
echo --- PostgreSQL Client ---
psql --version
if errorlevel 1 (
    echo WARN: psql client not in PATH (may still be installed as service)
)

echo.
echo --- pip ---
pip --version
if errorlevel 1 (
    echo FAIL: pip not found
    exit /b 1
)

echo.
echo Environment validation completed

exit /b 0
