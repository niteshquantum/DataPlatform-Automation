@echo off
setlocal

call "%~dp0stop_postgresql.bat"

echo Cleanup Completed

exit /b 0