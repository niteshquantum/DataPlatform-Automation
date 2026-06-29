@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\install_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\common\validate_java_runtime.bat"
if errorlevel 1 exit /b 1 

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\install_tools.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\deploy_mysql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\start_mysql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\create_database.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\run_liquibase.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\validate_environment.bat"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MYSQL SETUP SUCCESSFUL
echo =====================================
echo.

exit /b 0