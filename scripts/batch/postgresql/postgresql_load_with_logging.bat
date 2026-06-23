@echo off
setlocal

set PROJECT_ROOT=%~dp0..\..\..

if not exist "%PROJECT_ROOT%\logs" mkdir "%PROJECT_ROOT%\logs"

set LOG_FILE=%PROJECT_ROOT%\logs\postgresql_load_%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%.log

echo PostgreSQL Load Started: %DATE% %TIME% > "%LOG_FILE%"

call "%~dp0load_data.bat" >> "%LOG_FILE%" 2>&1

set RESULT=%ERRORLEVEL%

echo PostgreSQL Load Ended: %DATE% %TIME% >> "%LOG_FILE%"
echo Exit Code: %RESULT% >> "%LOG_FILE%"

type "%LOG_FILE%"

exit /b %RESULT%
