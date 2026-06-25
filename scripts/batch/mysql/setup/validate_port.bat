@echo off
setlocal

echo.
echo =====================================
echo VALIDATING MYSQL PORT
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

"%PROJECT_ROOT%\config\python.conf"
python "%PROJECT_ROOT%\scripts\python\mysql\setup\validate_port.py"

if errorlevel 1 (
echo.
echo PORT VALIDATION FAILED
exit /b 1
)

echo.
echo PORT VALIDATION SUCCESSFUL
echo.

exit /b 0
