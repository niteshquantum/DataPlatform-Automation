@echo off

set "PROJECT_ROOT=%CD%"

if not exist "%PROJECT_ROOT%\config\mysql.conf" (
echo ERROR: INVALID PROJECT ROOT
echo Current Directory: %PROJECT_ROOT%
exit /b 1
)
@REM echo Project Root Set To: %PROJECT_ROOT%