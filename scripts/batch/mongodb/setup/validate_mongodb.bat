@echo off
setlocal

echo.
echo =====================================
echo VALIDATING MONGODB
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

python "%PROJECT_ROOT%\scripts\python\mongodb\setup\validate_database.py"

if errorlevel 1 (
    echo.
    echo MONGODB VALIDATION FAILED
    exit /b 1
)

echo.
echo MONGODB VALIDATION SUCCESSFUL
echo.

exit /b 0