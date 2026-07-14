@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\start_postgresql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\setup\validate_postgresql.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\common\download_dataset.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\load\load_data.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\postgresql\load\validate_loaded_data.bat"
if errorlevel 1 exit /b 1

echo.
echo =====================================
echo POSTGRESQL LOAD SUCCESSFUL
echo =====================================
echo.

exit /b 0
