@echo off
setlocal

echo ==================================
echo MYSQL SETUP TEST
echo ==================================

call scripts\batch\common\validate_python_runtime.bat
if errorlevel 1 exit /b 1

call scripts\batch\mysql\setup\install_python_requirements.bat
if errorlevel 1 exit /b 1

call scripts\batch\mysql\setup\validate_python_requirements.bat
if errorlevel 1 exit /b 1

echo.
echo MYSQL SETUP TEST PASSED
echo.

exit /b 0