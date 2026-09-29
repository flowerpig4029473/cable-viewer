@echo off
chcp 65001 >nul
cd /d "%~dp0.."
"C:\Program Files\Git\cmd\git.exe" push -u origin main
echo.
pause
