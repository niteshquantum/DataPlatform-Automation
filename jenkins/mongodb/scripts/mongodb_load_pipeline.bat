@echo off

call scripts\batch\mongodb\load_data.bat

call scripts\batch\mongodb\validate_data.bat