@echo off

echo ===================================
echo Cleaning MongoDB Collections
echo ===================================

python "%~dp0..\..\python\mongodb\cleanup_collections.py"

pause