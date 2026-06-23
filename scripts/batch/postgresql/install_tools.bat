@echo off
setlocal

echo ============================================
echo INSTALL TOOLS FOR POSTGRESQL
echo ============================================

echo.
echo [1/3] Installing Terraform...
call "%~dp0..\common\install_terraform.bat"
if errorlevel 1 (
    echo WARNING: Terraform installation had issues
)

echo.
echo [2/3] Installing PostgreSQL JDBC Driver...
call "%~dp0..\common\install_postgresql_driver.bat"
if errorlevel 1 (
    echo WARNING: JDBC driver installation had issues
)

echo.
echo [3/3] Installing Liquibase...
call "%~dp0..\common\install_liquibase.bat"
if errorlevel 1 (
    echo WARNING: Liquibase installation had issues
)

echo.
echo [3/3] Validating Liquibase...
call "%~dp0..\common\validate_liquibase.bat"
if errorlevel 1 (
    echo WARNING: Liquibase validation had issues
)

echo.
echo Validating all tools...
call "%~dp0..\common\validate_tools.bat"

echo.
echo ============================================
echo Tool installation completed
echo ============================================

exit /b 0
