@echo off
setlocal

echo.
echo =====================================
echo VALIDATING MSSQL
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

python "%PROJECT_ROOT%\scripts\python\mssql\setup\validate_mssql.py"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL VALIDATION FAILED
    exit /b 1
)

echo.
echo =====================================
echo MSSQL VALIDATED
echo =====================================
echo.

exit /b 0