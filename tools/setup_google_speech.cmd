@echo off
python "%~dp0google_audiobook.py" setup --gui
if errorlevel 1 pause
