@echo off
setlocal

echo.
echo =====================================
echo VALIDATING CSV FILES
echo =====================================
echo.
call "%~dp0..\..\common\set_project_root.bat"
python "%PROJECT_ROOT%\scripts\python\mysql\load\validate_csv.py"

if errorlevel 1 (
    echo.
    echo CSV VALIDATION FAILED
    exit /b 1
)

echo.
echo CSV VALIDATION SUCCESSFUL
echo.

exit /b 0