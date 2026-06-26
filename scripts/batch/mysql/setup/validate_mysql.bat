@echo off
setlocal

echo.
echo =====================================
echo VALIDATING MYSQL
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"
echo PROJECT_ROOT=%PROJECT_ROOT%
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

exit /b 0