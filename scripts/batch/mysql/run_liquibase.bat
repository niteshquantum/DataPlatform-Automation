@echo off
setlocal EnableDelayedExpansion

REM =====================================
REM ROOT PATH
REM =====================================

set ROOT=%~dp0..\..\..

REM =====================================
REM CONFIG FILE
REM =====================================

set CONFIG=%ROOT%\config\mysql.conf

REM =====================================
REM READ CONFIG
REM =====================================

for /f "tokens=1,2 delims==" %%A in (%CONFIG%) do (
if "%%A"=="MYSQL_HOST" set MYSQL_HOST=%%B
if "%%A"=="MYSQL_PORT" set MYSQL_PORT=%%B
if "%%A"=="MYSQL_DB" set MYSQL_DB=%%B
if "%%A"=="MYSQL_USER" set MYSQL_USER=%%B
if "%%A"=="MYSQL_PASSWORD" set MYSQL_PASSWORD=%%B
)

REM =====================================
REM LIQUIBASE PATH
REM =====================================

set LB=%ROOT%\tools\liquibase\liquibase.bat

REM =====================================
REM JDBC DRIVER
REM =====================================

for %%f in ("%ROOT%\tools\drivers\*.jar") do (
    set DRIVER=%%f
)

REM =====================================
REM CHANGELOG
REM =====================================

set CHANGELOG=liquibase/mysql/master.xml


REM =====================================
REM GO TO PROJECT ROOT
REM =====================================

cd /d "%ROOT%"

echo.
echo =====================================
echo RUNNING LIQUIBASE
echo =====================================
echo.

echo Database : %MYSQL_DB%
echo Port     : %MYSQL_PORT%
echo User     : %MYSQL_USER%
echo Driver   : %DRIVER%
echo.

"%LB%" ^
--classpath="%DRIVER%" ^
--driver=com.mysql.cj.jdbc.Driver ^
--changeLogFile="%CHANGELOG%" ^
--url="jdbc:mysql://%MYSQL_HOST%:%MYSQL_PORT%/%MYSQL_DB%" ^
--username=%MYSQL_USER% ^
--password=%MYSQL_PASSWORD% ^
update


