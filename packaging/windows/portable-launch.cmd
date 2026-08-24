@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0portable-bootstrap.ps1"
if errorlevel 1 pause
