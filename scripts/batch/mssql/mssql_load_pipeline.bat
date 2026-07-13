@echo off
setlocal

call "%~dp0..\common\set_project_root.bat"

call "%PROJECT_ROOT%\scripts\batch\common\validate_python_runtime.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\mssql\setup\validate_python_requirements.bat"
if errorlevel 1 exit /b 1

call "%PROJECT_ROOT%\scripts\batch\common\validate_tools.bat"
if errorlevel 1 exit /b 1

@REM call "%PROJECT_ROOT%\scripts\batch\mssql\load\validate_mssql.bat"
@REM if errorlevel 1 exit /b 1

@REM call "%PROJECT_ROOT%\scripts\batch\mssql\load\validate_csv.bat"
@REM if errorlevel 1 exit /b 1

@REM call "%PROJECT_ROOT%\scripts\batch\mssql\load\load_data.bat"
@REM if errorlevel 1 exit /b 1

@REM call "%PROJECT_ROOT%\scripts\batch\mssql\load\validate_loaded_data.bat"
@REM if errorlevel 1 exit /b 1

echo.
echo =====================================
echo MSSQL LOAD SUCCESSFUL
echo =====================================
echo.

exit /b 0