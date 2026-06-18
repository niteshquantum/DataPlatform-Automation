@echo off

if not exist logs mkdir logs

if not exist logs\mongodb_setup.log (
    type nul > logs\mongodb_setup.log
)

if not exist logs\mongodb_load.log (
    type nul > logs\mongodb_load.log
)