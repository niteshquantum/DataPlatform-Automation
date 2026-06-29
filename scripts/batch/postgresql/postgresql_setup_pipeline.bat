@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\install_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\common\validate_java_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\install_tools.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\deploy_postgresql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\start_postgresql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\create_database.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\run_liquibase.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\validate_environment.bat"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo POSTGRESQL SETUP SUCCESSFUL
echo =====================================
echo.

exit /b 0