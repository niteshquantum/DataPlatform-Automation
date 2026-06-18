@echo off

call "%~dp0validate_port.bat"

if errorlevel 1 exit /b 1

call "%~dp0validate_mongodb.bat"

if errorlevel 1 exit /b 1

call "%~dp0validate_data.bat"

if errorlevel 1 exit /b 1

echo Environment Validation Completed