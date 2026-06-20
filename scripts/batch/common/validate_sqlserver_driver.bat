@echo off
setlocal

echo.
echo =====================================
echo VALIDATING SQL SERVER JDBC DRIVER
echo =====================================
echo.

set DRIVER=tools\drivers\mssql-jdbc.jar

if not exist "%DRIVER%" (
echo ERROR: JDBC DRIVER NOT FOUND
echo Expected: %DRIVER%
exit /b 1
)

echo Driver Found:
echo %DRIVER%

echo.
echo =====================================
echo SQL SERVER JDBC DRIVER VALIDATED
echo =====================================
echo.

exit /b 0