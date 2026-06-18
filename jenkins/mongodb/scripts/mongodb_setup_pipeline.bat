@echo off

call scripts\batch\mongodb\run_mongodb.bat

call scripts\batch\mongodb\deploy_mongodb.bat

call scripts\batch\mongodb\validate_data.bat