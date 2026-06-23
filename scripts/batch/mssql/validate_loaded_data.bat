@echo off

echo.
echo =====================================
echo VALIDATING LOADED DATA
echo =====================================
echo.

python scripts\python\mssql\validate_loaded_data.py

if errorlevel 1 (
echo LOADED DATA VALIDATION FAILED
exit /b 1
)

echo LOADED DATA VALIDATION SUCCESSFUL

exit /b 0