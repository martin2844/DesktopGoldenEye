@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\launcher\GoldenEye.ps1" -Action Launcher -Runtime Quality -InstallRoot "."
set "desktop_goldeneye_exit=%errorlevel%"
popd
if not "%desktop_goldeneye_exit%"=="0" pause
exit /b %desktop_goldeneye_exit%
