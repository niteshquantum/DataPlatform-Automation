@echo off

python scripts\python\mssql\validate_csv.py

if errorlevel 1 (
echo CSV VALIDATION FAILED
exit /b 1
)

echo CSV VALIDATION SUCCESSFUL

exit /b 0