@echo off

if not exist tools\terraform\terraform.exe (
    echo TERRAFORM NOT FOUND
    exit /b 1
)

if not exist tools\drivers\mysql-connector-j-9.5.0.jar (
    echo MYSQL DRIVER NOT FOUND
    exit /b 1
)

if not exist tools\liquibase\liquibase.bat (
    echo LIQUIBASE NOT FOUND
    exit /b 1
)

echo.
echo TOOLS VALIDATED SUCCESSFULLY
echo.