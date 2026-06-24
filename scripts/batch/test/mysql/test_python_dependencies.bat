@echo off
setlocal

echo ==================================
echo MYSQL PYTHON DEPENDENCY TEST
echo ==================================

call scripts\batch\mysql\setup\install_python_requirements.bat
if errorlevel 1 (
    echo INSTALL FAILED
    exit /b 1
)

call scripts\batch\mysql\setup\validate_python_requirements.bat
if errorlevel 1 (
    echo VALIDATION FAILED
    exit /b 1
)

echo.
echo TEST SUCCESSFUL
echo.

exit /b 0