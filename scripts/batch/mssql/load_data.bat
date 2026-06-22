@echo off

echo.
echo =====================================
echo MSSQL DATA LOAD
echo =====================================
echo.

python scripts\python\mssql\load_all.py

if errorlevel 1 (
echo DATA LOAD FAILED
exit /b 1
)

echo DATA LOAD SUCCESSFUL

exit /b 0