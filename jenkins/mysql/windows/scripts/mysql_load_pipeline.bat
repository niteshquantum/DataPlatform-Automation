@echo off

call scripts\batch\mysql\validate_environment.bat
if errorlevel 1 exit /b 1

call scripts\batch\mysql\validate_csv.bat
if errorlevel 1 exit /b 1

call scripts\batch\mysql\load_data.bat
if errorlevel 1 exit /b 1

echo MYSQL LOAD PIPELINE COMPLETED