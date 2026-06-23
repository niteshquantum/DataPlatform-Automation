@echo off

echo.
echo =====================================
echo VALIDATING MSSQL
echo =====================================
echo.

python scripts\python\mssql\validate_mssql.py

if errorlevel 1 (
echo MSSQL VALIDATION FAILED
exit /b 1
)

echo.
echo MSSQL VALIDATION SUCCESSFUL
echo.

exit /b 0