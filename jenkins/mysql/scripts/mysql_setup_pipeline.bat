@echo off

call scripts\batch\mysql\initialize_logs.bat

call scripts\batch\mysql\validate_environment.bat
if errorlevel 1 exit /b 1

call scripts\batch\mysql\deploy_mysql.bat
if errorlevel 1 exit /b 1

call scripts\batch\mysql\create_database.bat
if errorlevel 1 exit /b 1

call scripts\batch\mysql\run_liquibase.bat
if errorlevel 1 exit /b 1

echo MYSQL SETUP PIPELINE COMPLETED