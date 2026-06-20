@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo RUNNING SQL SERVER LIQUIBASE
echo =====================================
echo.

REM =====================================
REM PROJECT ROOT
REM =====================================

set "ROOT=%CD%"
set "LB_BAT=%ROOT%\tools\liquibase\liquibase.bat"
set "PROP_FILE=%ROOT%\liquibase\sqlserver\liquibase.properties"

REM =====================================
REM VALIDATE LIQUIBASE
REM =====================================

call scripts\batch\common\validate_liquibase.bat

if errorlevel 1 (
exit /b 1
)

REM =====================================
REM VALIDATE FILES
REM =====================================

if not exist "%LB_BAT%" (
echo ERROR: LIQUIBASE NOT FOUND
echo Expected: %LB_BAT%
exit /b 1
)

if not exist "%PROP_FILE%" (
echo ERROR: LIQUIBASE PROPERTIES NOT FOUND
echo Expected: %PROP_FILE%
exit /b 1
)

if not exist "liquibase\sqlserver\master.xml" (
echo ERROR: MASTER CHANGELOG NOT FOUND
exit /b 1
)

echo.
echo Liquibase Home : %LB_BAT%
echo Properties     : %PROP_FILE%
echo.

java -version

if errorlevel 1 (
echo ERROR: JAVA NOT AVAILABLE
exit /b 1
)

echo.
echo =====================================
echo EXECUTING LIQUIBASE UPDATE
echo =====================================
echo.

call "%LB_BAT%" ^
--defaults-file="%PROP_FILE%" ^
update

if errorlevel 1 (
echo.
echo ERROR: LIQUIBASE UPDATE FAILED
exit /b 1
)

echo.
echo =====================================
echo LIQUIBASE UPDATE COMPLETED
echo =====================================
echo.

exit /b 0
