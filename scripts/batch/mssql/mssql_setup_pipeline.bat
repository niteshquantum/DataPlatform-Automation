@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\install_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\common\validate_java_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\install_mssql_tools.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\deploy_mssql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\start_mssql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\create_database.bat"
if errorlevel 1 exit /b 1


call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_environment.bat"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MSSQL SETUP SUCCESSFUL
echo =====================================
echo.

exit /b 0
