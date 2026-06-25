@echo off

echo.
echo =====================================
echo VALIDATING MYSQL
echo =====================================
echo.

python "%PROJECT_ROOT%\scripts\python\mysql\load\validate_data.py"

if errorlevel 1 (
    echo.
    echo MYSQL VALIDATION FAILED
    exit /b 1
)

echo.
echo MYSQL VALIDATION SUCCESSFUL
echo.