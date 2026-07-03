#!/bin/bash

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "VALIDATING PYTHON REQUIREMENTS"
echo "====================================="
echo

if ! command -v python3 >/dev/null 2>&1
then
    echo "ERROR: Python3 not found."
    exit 1
fi

echo "Using Python:"
which python3

python3 --version

echo

echo "Checking PyYAML..."
python3 -c "import yaml"

if [ $? -ne 0 ]
then
    echo "ERROR: PyYAML not installed."
    exit 1
fi

echo "Checking python-dotenv..."
python3 -c "import dotenv"

if [ $? -ne 0 ]
then
    echo "ERROR: python-dotenv not installed."
    exit 1
fi

echo "Checking pyodbc..."
python3 -c "import pyodbc"

if [ $? -ne 0 ]
then
    echo "ERROR: pyodbc not installed."
    exit 1
fi

echo "Checking pandas..."
python3 -c "import pandas"

if [ $? -ne 0 ]
then
    echo "ERROR: pandas not installed."
    exit 1
fi

echo
echo "====================================="
echo "PYTHON REQUIREMENTS VALIDATED"
echo "====================================="
echo

exit 0