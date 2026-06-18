@echo off

call "%~dp0initialize_logs.bat"

echo =================================== >> logs\mongodb_setup.log
echo MongoDB Setup Started >> logs\mongodb_setup.log
echo =================================== >> logs\mongodb_setup.log

call "%~dp0run_mongodb.bat"

call "%~dp0deploy_mongodb.bat"

call "%~dp0validate_data.bat"

echo MongoDB Setup Completed >> logs\mongodb_setup.log