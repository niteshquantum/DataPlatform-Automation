@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mysql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mongodb\setup\start_mongodb.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mongodb\setup\validate_mongodb.bat"
if errorlevel 1 exit /b 1


call "%PROJECT_ROOT%\scripts\batch\mongodb\load\load_data.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mongodb\load\validate_loaded_data.bat"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MONGODB LOAD SUCCESSFUL
echo =====================================
echo.

exit /b 0