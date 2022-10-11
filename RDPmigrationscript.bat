@echo OFF

:: verify host is a Windows 7 machine
REM systeminfo | findstr /I "OS Name" | find "Windows 7" >nul 2>&1
for /f "skip=1 tokens=1,2,3 delims=^|" %%o in ('wmic os list status ^| findstr /vr "^$"') DO SET "OS=%%o"
echo %OS% | find "Windows 7" >nul 2>&1
if %errorlevel% EQU 1 GOTO NOT_WIN7

:: verify the number of users attached to remote setting on machines
REM sysdm.cpl | findstr /I "Remote" | find "Remote Desktop Users" >nul 2>&1

echo


net user User1 User1 /add

net user User2 User2 /add 

net localgroup administrators User2 /add

net localgroup Remote Desktop Users

:opens remote users and groups
cmd"lusrmgr.msc"