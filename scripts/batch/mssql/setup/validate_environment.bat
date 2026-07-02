@echo off
setlocal

echo.
echo =====================================
echo VALIDATING MSSQL ENVIRONMENT
echo =====================================
echo.

call "%~dp0..\..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_tools.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_port.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_mssql.bat"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MSSQL ENVIRONMENT VALIDATED
echo =====================================
echo.

exit /b 0