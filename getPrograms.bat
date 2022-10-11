@echo OFF

cls

if [%1]==[] GOTO NOARG

REM check if we can access the remote machine's registry
echo|set/p=Checking registry connection to %~n1...
reg query "\\%~n1\HKEY_LOCAL_MACHINE" >nul 2>&1

if %ERRORLEVEL%==1 GOTO NOREGISTRY

echo GOOD!

REM this script supports being ran from/with UNC paths or not
SET UNC=0
SET outDir=

REM if script was executed from UNC path then current directory will be C:\Windows
setlocal EnableDelayedExpansion
if /I "%cd%"=="%SystemRoot%" (
	SET UNC=1
	
	for /F "tokens=2,*" %%a in ('net use * "%~1" 2^>nul') DO @(
		if %ERRORLEVEL% NEQ 0 GOTO NOUNC
		if not defined outDir (
			pushd "\\%~p0"
			SET outDir=%%a
		)
	)
) else (
	SET outDir=%~1
)

echo Using !outDir! to save files
echo Working @ %cd%
echo.

REM regardless of cmd.exe bitness (32-bit @ %windir%\SysWoW64\cmd.exe) OR (64-bit @ %windir%\System32\cmd.exe)
REM reg query {\\MACHINE\}HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall /reg:64 >> all_programs
REM reg query {\\MACHINE\}HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall /reg:32 >> all_programs

REM without specifying the registry (32-bit or 64-bit)
REM reg query {\\MACHINE\}HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall >> all_programs
REM reg query {\\MACHINE\}HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall >> all_programs

REM delete old programs details if they exists from a previous run
if exist "!outDir!\all_programs" DEL "!outDir!\all_programs"
if exist "!outDir!\get_these" DEL "!outDir!\get_these"
if exist "!outDir!\programs.csv" DEL "!outDir!\programs.csv"
if exist "!outDir!\programs.xlsx" DEL "!outDir!\programs.xlsx"
if exist "!outDir!\unknowns.txt" DEL "!outDir!\unknowns.txt"

REM get all uninstallable registry entries for both 32-bit and 64-bit
echo Querying all uninstallable programs...
reg query "\\%~n1\HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall" >> "!outDir!\all_programs"
reg query "\\%~n1\HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" >> "!outDir!\all_programs"

REM find all lines that are NOT (/V) in common list OR empty lines
echo now filtering...
findstr /I /V /G:"%~dp0common" "!outDir!\all_programs" | findstr /VR "^$" >> "!outDir!\get_these"

REM create beginnings of csv file for Excel prettiness
echo|set/p=generating spreadsheet...
echo sep=;>"!outDir!\programs.csv"
echo Name;Publisher;Version; Installed>>"!outDir!\programs.csv"

for /F "tokens=*" %%n IN ('type "!outDir!\get_these"') DO @(
	SET disp=
	SET pub=
	SET ver=
	SET inst=
		
	for /F "tokens=2,*" %%a in ('reg query "\\%~n1\%%n" /v DisplayName 2^>nul') DO SET disp="%%b;"
	if "!disp!"=="" (
		echo No DisplayName for %%n >> "!outDir!\unknowns.txt"
		echo|set/p=UNKNOWN;>> "!outDir!\programs.csv"
	) else echo|set/p=!disp!>> "!outDir!\programs.csv"
	
	for /F "tokens=2,*" %%c in ('reg query "\\%~n1\%%n" /v Publisher 2^>nul') DO SET pub="%%d;"
	if "!pub!"=="" (
		echo No Publisher for %%n >> "!outDir!\unknowns.txt"
		echo|set/p=;>> "!outDir!\programs.csv"
	) else echo|set/p=!pub!>> "!outDir!\programs.csv"
	
	for /F "tokens=2,*" %%e in ('reg query "\\%~n1\%%n" /v DisplayVersion 2^>nul') DO SET ver=%%f
	if "!ver!"=="" (echo|set/p=;>> "!outDir!\programs.csv") else echo|set/p=!ver!;>> "!outDir!\programs.csv"
	
	for /F "tokens=2,*" %%g in ('reg query "\\%~n1\%%n" /v InstallDate 2^>nul') DO SET inst=%%h
	if "!inst!"=="" (echo.>> "!outDir!\programs.csv") else (
		echo !inst:~4,2!/!inst:~6,2!/!inst:~0,4!>> "!outDir!\programs.csv"
	)
)

REM convert to nicer xlsx format
pushd "\\tccdav1b\Global\ePlus\TCH Refresh\bScripts\python"
call pyRunner.bat programs.py "!outDir!\programs.csv"
popd
echo complete^^!

DEL "!outDir!\all_programs"
DEL "!outDir!\get_these"
DEL "!outDir!\programs.csv"

if !UNC! EQU 1 (
	echo.
	echo Removing UNC environment...
	net use !outDir! /D
	popd
)
endlocal
GOTO:eof

:NOARG
setlocal EnableDelayedExpansion
for /F "tokens=1 delims=" %%a in ('wmic computersystem get name ^| findstr /v "Name" ^| findstr /vr "^$"') DO SET disp=%%a
echo No machine name was supplied...
echo Example: displayNames.bat !disp!
endlocal
exit /b 1

:NOREGISTRY
echo Unable to access the remote machine's registry...
echo Please ensure the unit is on and the Remote Registry Service is running.
exit /b 2

:NOUNC
echo UNC mapping was invalid...
echo The expected environment could not be established.
exit /b 3

cmd /k
