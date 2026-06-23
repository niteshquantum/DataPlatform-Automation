@echo off
setlocal

echo.
echo =====================================
echo INSTALLING MSSQL TOOLS
echo =====================================
echo.

echo [1/3] Installing SQLCMD...
call "%~dp0install_sqlcmd.bat"

if errorlevel 1 (
echo ERROR: SQLCMD INSTALL FAILED
exit /b 1
)

echo [2/3] Installing MSSQL JDBC Driver...
call "%~dp0install_mssql_driver.bat"

if errorlevel 1 (
echo ERROR: MSSQL JDBC DRIVER INSTALL FAILED
exit /b 1
)

echo [3/3] Validating MSSQL Tools...
call "%~dp0validate_mssql_tools.bat"

if errorlevel 1 (
echo ERROR: MSSQL TOOL VALIDATION FAILED
exit /b 1
)

echo.
echo =====================================
echo MSSQL TOOLS INSTALLED
echo =====================================
echo.

exit /b 0
