@echo off

call "%~dp0initialize_logs.bat"

echo =================================== >> logs\mongodb_load.log
echo MongoDB Load Started >> logs\mongodb_load.log
echo =================================== >> logs\mongodb_load.log

call "%~dp0load_data.bat"

call "%~dp0validate_data.bat"

echo MongoDB Load Completed >> logs\mongodb_load.log