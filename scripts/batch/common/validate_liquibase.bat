@echo off
setlocal EnableDelayedExpansion

echo.
echo =====================================
echo VALIDATING LIQUIBASE
echo =====================================
echo.

REM =====================================
REM PROJECT ROOT
REM =====================================

set "ROOT=%CD%"
if not exist "%ROOT%\config\mysql.conf" (    
set "ROOT=%~dp0..\..\.."

)

set "CONFIG_FILE=%ROOT%\config\mysql.conf"

if not exist "%CONFIG_FILE%" (
echo ERROR: MYSQL CONFIG NOT FOUND
echo Expected: %CONFIG_FILE%
exit /b 1
)

REM =====================================
REM READ CONFIG
REM =====================================

for /f "tokens=1,2 delims==" %%A in (%CONFIG_FILE%) do (
if /I "%%A"=="LIQUIBASE_VERSION" set "EXPECTED_VERSION=%%B"
)

if not defined EXPECTED_VERSION (
echo ERROR: LIQUIBASE_VERSION NOT FOUND IN mysql.conf
exit /b 1
)

set "LIQUIBASE_HOME=%ROOT%\tools\liquibase"
set "LIQUIBASE_BAT=%LIQUIBASE_HOME%\liquibase.bat"

echo Expected Liquibase Version : %EXPECTED_VERSION%
echo.

REM =====================================
REM VALIDATE PATHS
REM =====================================

if not exist "%LIQUIBASE_HOME%" (
echo ERROR: LIQUIBASE DIRECTORY NOT FOUND
exit /b 1
)

if not exist "%LIQUIBASE_BAT%" (
echo ERROR: LIQUIBASE.BAT NOT FOUND
exit /b 1
)

REM =====================================
REM VALIDATE JAVA
REM =====================================

where java >nul 2>&1

if errorlevel 1 (
echo ERROR: JAVA NOT FOUND
exit /b 1
)

echo Java Found:
where java

echo.
echo Checking Liquibase Version...
echo.

call "%LIQUIBASE_BAT%" --version > "%TEMP%\liquibase_version.txt" 2>&1

if errorlevel 1 (
echo ERROR: LIQUIBASE EXECUTION FAILED
del "%TEMP%\liquibase_version.txt" >nul 2>&1
exit /b 1
)

type "%TEMP%\liquibase_version.txt"

findstr /C:"Liquibase Version: %EXPECTED_VERSION%" "%TEMP%\liquibase_version.txt" >nul

if errorlevel 1 (
echo.
echo ERROR: LIQUIBASE VERSION MISMATCH
echo Expected : %EXPECTED_VERSION%
del "%TEMP%\liquibase_version.txt" >nul 2>&1
exit /b 1
)

del "%TEMP%\liquibase_version.txt" >nul 2>&1

echo.
echo =====================================
echo LIQUIBASE VALIDATED
echo =====================================
echo.

exit /b 0
