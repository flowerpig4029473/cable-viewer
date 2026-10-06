@echo off
rem 바뀐 내용(게시한 케이블 포함)을 GitHub에 올린다. 1~2분 뒤 QR 화면에 반영.
cd /d "%~dp0.."
set GIT="C:\Program Files\Git\cmd\git.exe"
%GIT% add report.json cables
%GIT% diff --cached --quiet || %GIT% commit -q -m "보고 게시"
%GIT% push -u origin main
echo.
pause