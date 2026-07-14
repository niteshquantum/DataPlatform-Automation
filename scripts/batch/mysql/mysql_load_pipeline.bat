@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\start_mysql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\validate_mysql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\load\validate_csv.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\load\load_data.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\load\validate_loaded_data.bat"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MYSQL LOAD SUCCESSFUL
echo =====================================
echo.

exit /b 0