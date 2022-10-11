@echo OFF

:: verify host is a Windows 7 machine
REM systeminfo | findstr /I "OS Name" | find "Windows 7" >nul 2>&1
for /f "skip=1 tokens=1,2,3 delims=^|" %%o in ('wmic os list status ^| findstr /vr "^$"') DO SET "OS=%%o"
echo %OS% | find "Windows 7" >nul 2>&1
if %errorlevel% EQU 1 GOTO NOT_WIN7

:: verify script has not ran by looking for breadcrumb file
if exist "%USERPROFILE%\Documents\OneDriveMigration.txt" GOTO BEEN_DONE

:: dump this user's network drives for this machine
for /f "delims=" %%h in ('hostname') DO SET HOST=%%h
call "%~dp0rez\net_user_drives.bat" "%HOST%" "%username%"

:: dump printers list
wmic printer list brief > "\\tccdav1b\Global\scouting\%HOST%\printers.txt"

:: check that OneDrive is running
:MIGRATE_START
tasklist /fi "ImageName eq OneDrive.exe" /fo csv 2>NUL | find /I "onedrive.exe">NUL
if %errorlevel%==1 (
	if exist "%LocalAppData%\Microsoft\OneDrive\onedrive.exe" start "" "%LocalAppData%\Microsoft\OneDrive\onedrive.exe" else (
		if exist "C:\Program Files (x86)\Microsoft OneDrive\onedrive.exe" start "" "C:\Program Files (x86)\Microsoft OneDrive\onedrive.exe" else (
			if exist "C:\Program Files\Microsoft OneDrive\onedrive.exe" start "" "C:\Program Files\Microsoft OneDrive\onedrive.exe" else GOTO INSTALL_ONEDRIVE
		)
	)
)

tasklist /fi "ImageName eq OneDrive.exe" /fo csv 2>NUL | find /I "onedrive.exe">NUL
if %errorlevel%==1 (
	echo OneDrive does not appear to be running!
	GOTO ONEDRIVE_HELP
)

echo You should now have a OneDrive cloud icon in the icon tray (next to your clock),
echo however if this is your first time using OneDrive you may have a crossed out 
echo blue cloud while it sets-up; and you should get a notice in about 2-5 minutes
echo indicating that OneDrive is connected and syncing.
echo.
echo Please ensure you are logged into OneDrive and its cloud icon is 
echo solid blue (NOT CROSSED OUT) before continuing.
PAUSE

reg query "HKCU\Software\Microsoft\OneDrive\Accounts\Business1\Tenants\OneDrive - Texas Children's" >nul
if %errorlevel%==0 (
	if exist "%USERPROFILE%\OneDrive - Texas Children's\" (
		GOTO ONEDRIVE_MIGRATE
	) else (
		mkdir "%USERPROFILE%\OneDrive - Texas Children's"
		GOTO ONEDRIVE_MIGRATE
	)	
) else (
	set /A ATTEMPTS=1
	GOTO ONEDRIVE_SETUP
)

:ONEDRIVE_SETUP
reg query "HKCU\Software\Microsoft\OneDrive\Accounts\Business1\Tenants\OneDrive - Texas Children's"
if %errorlevel%==0 (
	if exist "%USERPROFILE%\OneDrive - Texas Children's\" (
		GOTO ONEDRIVE_MIGRATE
	) else (
		mkdir "%USERPROFILE%\OneDrive - Texas Children's"
		GOTO ONEDRIVE_MIGRATE
	)
) else (
	echo OneDrive does not appear to be setup correctly for %USERPROFILE%\OneDrive - Texas Children's!
	echo Please login and setup your OneDrive folder to the default location %USERPROFILE%\OneDrive - Texas Children's
	start odopen://sync?useremail=%USERNAME%@texaschildrens.org
	
	echo Once completed please continue here
	PAUSE
	set /A ATTEMPTS=%ATTEMPTS%+1

	if /i %ATTEMPTS%==3 if not exist "%USERPROFILE%\OneDrive - Texas Children's\" GOTO ONEDRIVE_HELP
	GOTO ONEDRIVE_SETUP
)

:INSTALL_ONEDRIVE
echo.
echo.
echo OneDrive could not be found and needs to be (re)installed/updated to continue!
echo Please install OneDrive from the open Software Center window and make sure to run it before continuing.
start %SystemRoot%\CCM\ClientUX\SCClient.exe softwarecenter:SoftwareID=ScopeId_B84B4603-8011-46F6-A31B-AE58A9D4EC29/Application_cb4cdd0c-bd56-47bf-bde8-0cf4d7bb7543
PAUSE
GOTO MIGRATE_START
:ONEDRIVE_HELP
echo You appear to be having issues setting up OneDrive, please contact IS for help @
echo Service Desk: 832-824-3512
echo.
echo Once OneDrive is configured properly you may run this script again.
PAUSE
GOTO:eof

:ONEDRIVE_MIGRATE
:: check currently backed up user folder configuration
:: KfmFoldersProtectedNow -> HKCU\Software\Microsoft\OneDrive\Accounts\Business1
:: DESK = 0x200"
:: DOCS = 0x400"
:: PICS = 0x800"
:: DESK+DOCS = 0x600
:: DESK+PICS = 0xA00
:: DOCS+PICS = 0xC00
:: ALL 		 = 0xE00

for /f "tokens=3" %%v in ('reg query "HKCU\Software\Microsoft\OneDrive\Accounts\Business1" /v "KfmFoldersProtectedNow" 2^>nul') DO SET "KFM=%%v"

SET /A "DESK=KFM&0x200"
SET /A "DOCS=KFM&0x400"
SET /A "PICS=KFM&0x800"

:: copy user files to OneDrive migration folder
:: only copies those which are NOT hidden
if not exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\" mkdir "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration"
echo.
echo Copying your user profile to OneDrive now... This will likely take a while!
echo Please do not interrupt this process or use your computer at this time, thanks.
timeout /t 7 /nobreak >nul 2>&1
for /F "tokens=*" %%n IN ('dir /b "%USERPROFILE%" ^| findstr /VI "onedrive" ^| findstr /VR "^\."') DO @(
	if exist "%USERPROFILE%\%%n\*" (
		REM echo D|xcopy "%USERPROFILE%\%%n" "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\%%n" /H /E /Y /B /Q /K >nul 2>&1
		mklink /J "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\%%n" "%USERPROFILE%\%%n" >nul 2>&1
	) else (
		echo F|xcopy "%USERPROFILE%\%%n" "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\%%n" /H /E /Y /B /Q /K >nul 2>&1
	)
)

:: copy user AppData (directed by .\rez\appdats file contents)
setlocal EnableDelayedExpansion
if exist "%~dp0rez\appdats" (
	:: create hidden AppData
	if not exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData\" mkdir "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData" >nul 2>&1
	attrib +h "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData" >nul 2>&1

	:: for UNC we must strip out "\Windows\" as it defaults to this working dir
	if /I "%cd%"=="%SystemRoot%" (
		set wdir=\Windows\
	) else set wdir=%~p0
	call :strLen wdir wlen
	
	:: current AppData location to copy from
	set appdir=%AppData:~0,-7%
	echo Backing up indicated user AppData files from !appdir!...
	
	for /F "tokens=*" %%A in ('type %~dp0rez\appdats') do (
		set cfile=%%~nxA
		set apper=%%~pA
		
		call set appath=%%apper:~!wlen!%%

		REM echo path: !appath! file: !cfile!
		if exist "!appdir!%%A" (
			if exist "!appdir!%%A\*" (
				set "outdir=%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData\!appath!!cfile!"
				if not exist "!outdir!" mkdir "!outdir!" >nul 2>&1
				
				REM echo copying folder !appdir!%%A to !outdir!
				echo D|xcopy /q /s /h /y "!appdir!%%A" "!outdir!" >nul 2>&1
			) else (
				set "outdir=%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData\!appath!"
				if not exist "!outdir!" mkdir "!outdir!" >nul 2>&1
				
				REM echo copying file !appdir!%%A to !outdir!
				copy "!appdir!%%A" "!outdir!" >nul 2>&1
			)
		)
	)
) else (
	echo No appdats file was supplied... skipping user AppData files
)

if exist "%~dp0rez\anydats" (
	echo Backing up indicated user fullpath files...
	:: create hidden AllData
	if not exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\" mkdir "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData" >nul 2>&1
	attrib +h "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData" >nul 2>&1
		
	for /F "tokens=*" %%A in ('type %~dp0rez\anydats') do (
		if exist "%%A" (
			SET ff=%%~dpfxA
			if exist "%%A\*" (
				REM echo copying folder %%A to %USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!ff::=$!
				echo D|xcopy /q /s /h /y "%%A" "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!ff::=$!" >nul 2>&1
			) else (
				REM echo copying file %%A to %USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!ff::=$!
				call :GET_PD "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!ff::=$!
				if not exist "!PD!" mkdir "!PD!"
				copy "%%A" "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!ff::=$!" >nul 2>&1
			)
		) else echo %%A skipped for not existing		
	)
		
) else (
	echo No dats file was supplied... skipping user fullpath files
)

endlocal
echo User profile backup completed!
echo.
call "%~dp0rez\ProfileMapper.bat"

:: copied file storage size
for /f "tokens=*" %%z in ('""%~dp0rez\sizer.bat" "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration""') DO SET "oSize=%%z"

:: dump copied files list
dir /b /s /a "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration">"\\tccdav1b\Global\scouting\%HOST%\%username%-migrated.txt"
echo %oSize%>>"\\tccdav1b\Global\scouting\%HOST%\%username%-migrated.txt"
tree /f /a>"\\tccdav1b\Global\scouting\%HOST%\%username%-migrated.tree"

:: dump Outlook archives catalogs
call "%~dp0OutlookPstMigrate.bat"
REM call OutlookPstMigrate.bat %HOST% REMAP

:: leaves breadcrumb file to indicate the script was previously ran
for /f "tokens=*" %%p in ('time /t') DO echo|set/p=[ %%p ] > "%USERPROFILE%\Documents\OneDriveMigration.txt"
date /t >>"%USERPROFILE%\Documents\OneDriveMigration.txt"
dir /b /s /a "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration">>"%USERPROFILE%\Documents\OneDriveMigration.txt"
echo %oSize%>>"%USERPROFILE%\Documents\OneDriveMigration.txt"

echo.
echo.
echo.
echo.
echo.
echo Your user data (Desktops, Documents, Downloads, etc.) have been
echo copied over to your OneDrive and are now syncing.
echo.
echo !! Note !!
echo All executable files/programs/installers must be manually move/saved 
echo elsewhere such as a network drive (H:\, S:\, G:\, etc.) and are now
echo marked with a red x on their icons indicating they are not allowed on OneDrive.
echo.
echo.
echo Thank you for working with us to retain your data!
echo - The IS Team @ Service Desk: 832-824-3512
PAUSE
echo Goodbye
GOTO:eof

:GET_PD
SET PD=%~dp1
exit /b

:BEEN_DONE
echo This script has already been ran on this system!
GOTO CONTACT_IS

:NOT_WIN7
echo This script is intended for Windows 7 systems only!
GOTO CONTACT_IS

:CONTACT_IS
echo Please contact IS for help @ Service Desk: 832-824-3512
echo.
PAUSE
echo Goodbye
GOTO:eof

:strLen
setlocal enabledelayedexpansion

:strLen_Loop
   if not "!%1:~%len%!"=="" set /A len+=1 & goto :strLen_Loop
(endlocal & set %2=%len%)
exit /b
