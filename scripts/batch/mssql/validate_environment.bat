@echo off
setlocal

echo.
echo =====================================
echo ENVIRONMENT VALIDATION STARTED
echo =====================================
echo.

echo [1/5] Validating Python Runtime...
call scripts\batch\common\validate_python_runtime.bat
if errorlevel 1 exit /b 1

echo [2/5] Validating Python Requirements...
call scripts\batch\validate_python_requirements.bat
if errorlevel 1 exit /b 1

echo [3/5] Validating Tools...
call scripts\batch\common\validate_tools.bat
if errorlevel 1 exit /b 1

echo [4/5] Validating MSSQL...
call scripts\batch\mssql\validate_mssql.bat
if errorlevel 1 exit /b 1

echo [5/5] Environment Validation Complete

echo.
echo =====================================
echo ENVIRONMENT VALIDATION SUCCESSFUL
echo =====================================
echo.

exit /b 0