@echo off
setlocal

echo ============================================
echo VALIDATE PYTHON REQUIREMENTS
echo ============================================

python -c "import psycopg2; print('psycopg2:', psycopg2.__version__)"
if errorlevel 1 (
    echo FAIL: psycopg2 not available
    exit /b 1
)

python -c "import pandas; print('pandas:', pandas.__version__)"
if errorlevel 1 (
    echo FAIL: pandas not available
    exit /b 1
)

echo Python requirements validated successfully

exit /b 0
