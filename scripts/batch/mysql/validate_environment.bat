@echo off
setlocal

echo.
echo =====================================
echo ENVIRONMENT VALIDATION STARTED
echo =====================================
echo.

echo [1/6] Validating Python Runtime...
call scripts\batch\common\validate_python_runtime.bat
if errorlevel 1 (
echo ERROR: PYTHON RUNTIME VALIDATION FAILED
exit /b 1
)

echo [2/6] Validating Python Requirements...
call scripts\batch\validate_python_requirements.bat
if errorlevel 1 (
echo ERROR: PYTHON REQUIREMENTS VALIDATION FAILED
exit /b 1
)

echo [3/6] Validating Tools...
call scripts\batch\common\validate_tools.bat
if errorlevel 1 (
echo ERROR: TOOLS VALIDATION FAILED
exit /b 1
)

echo [4/6] Validating MySQL Port...
call scripts\batch\mysql\validate_port.bat
if errorlevel 1 (
echo ERROR: MYSQL PORT VALIDATION FAILED
exit /b 1
)

echo [5/6] Validating MySQL...
call scripts\batch\mysql\validate_mysql.bat
if errorlevel 1 (
echo ERROR: MYSQL VALIDATION FAILED
exit /b 1
)

echo [6/6] Validating CSV Files...
call scripts\batch\mysql\validate_csv.bat
if errorlevel 1 (
echo ERROR: CSV VALIDATION FAILED
exit /b 1
)

echo.
echo =====================================
echo ENVIRONMENT VALIDATION SUCCESSFUL
echo =====================================
echo.

exit /b 0
