@echo off

call "%~dp0install_mysql_driver.bat"
if errorlevel 1 exit /b 1

call "%~dp0install_liquibase.bat"
if errorlevel 1 exit /b 1

echo.
echo TOOLS INSTALLED SUCCESSFULLY
echo.