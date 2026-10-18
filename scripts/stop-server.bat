@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1" -Action stop %*
exit /b %ERRORLEVEL%
