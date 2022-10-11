
:: verify host is a Windows 7 machine
REM systeminfo | findstr /I "OS Name" | find "Windows 7" >nul 2>&1
for /f "skip=1 tokens=1,2,3 delims=^|" %%o in ('wmic os list status ^| findstr /vr "^$"') DO SET "OS=%%o"
echo %OS% | find "Windows 7" >nul 2>&1
if %errorlevel% EQU 1 echo NOT_WIN7

cmd /k

