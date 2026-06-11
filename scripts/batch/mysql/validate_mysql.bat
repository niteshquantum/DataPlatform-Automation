@echo off

echo.
echo =====================================
echo VALIDATING MYSQL
echo =====================================
echo.

python scripts\python\mysql\validate_mysql.py

if errorlevel 1 (
    echo.
    echo MYSQL VALIDATION FAILED
    exit /b 1
)

echo.
echo MYSQL VALIDATION SUCCESSFUL
echo.