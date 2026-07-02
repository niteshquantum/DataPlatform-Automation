@echo off
setlocal

echo.
echo =====================================
echo VALIDATING MSSQL PORT
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

python "%PROJECT_ROOT%\scripts\python\mssql\setup\validate_port.py"

if errorlevel 1 (
    echo.
    echo ERROR: MSSQL PORT VALIDATION FAILED
    exit /b 1
)

echo.
echo =====================================
echo MSSQL PORT VALIDATED
echo =====================================
echo.

exit /b 0