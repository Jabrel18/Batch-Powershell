@echo OFF

:: verify script has not ran by looking for breadcrumb file
if exist "%USERPROFILE%\Documents\OneDriveMigration.txt" GOTO BEEN_DONE

:: verify host is a Windows 10 machine
systeminfo | findstr /I "OS Name" | find "Windows 10" >nul 2>&1
if %errorlevel% EQU 1 GOTO NOT_WIN10

echo Restoring user data...

:: check that OneDrive is running
:RESTORE_START
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

reg query "HKCU\Software\Microsoft\OneDrive\Accounts\Business1\Tenants\OneDrive - Texas Children's"
if %errorlevel%==0 (
	if exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\" (
		GOTO PROFILE_RESTORE
	) else (
		echo No profile migration appears to have been performed as the location %USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration is empty^^!
		echo Exiting...
		exit /b 2
		GOTO:eof
	)
) else (
	set /A ATTEMPTS=1
	GOTO ONEDRIVE_SETUP
)

:ONEDRIVE_SETUP
reg query "HKCU\Software\Microsoft\OneDrive\Accounts\Business1\Tenants\OneDrive - Texas Children's"
if %errorlevel%==0 (
	if exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\" (
		GOTO PROFILE_RESTORE
	) else (
		echo No profile migration appears to have been performed as the location %USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration is empty^^!
		echo Exiting...
		exit /b 2
		GOTO:eof
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
GOTO RESTORE_START
:ONEDRIVE_HELP
echo You appear to be having issues setting up OneDrive, please contact IS for help @
echo Service Desk: 832-824-3512
echo.
echo Once OneDrive is configured properly you may run this script again.
PAUSE
GOTO:eof

:BEEN_DONE
echo This script has already been ran on this system!
GOTO CONTACT_IS

:NOT_WIN10
echo This script is intended for Windows 10 systems only!
GOTO CONTACT_IS

:CONTACT_IS
echo Please contact IS for help @ Service Desk: 832-824-3512
echo.
PAUSE
echo Goodbye
GOTO:eof

:PROFILE_RESTORE
:: update profile mappings (deprecated)
REM call "%~dp0rez\ProfileMapper.bat"

echo.
echo Preparing to restore fullpath files...
timeout /t 3 /nobreak >nul 2>&1

:: restore AnyData files (full paths)
setlocal EnableDelayedExpansion
if exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\" (
	if exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData" attrib +h "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData" >nul 2>&1
	for /f "tokens=*" %%n in ('dir /b "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData"') DO (
		SET drive=%%n
		echo restoring !drive:$=:! drive
		if exist "!drive:$=:!" (
			for /f "tokens=*" %%o in ('dir /b "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive::=$!"') DO (
				REM echo restoring %%o from "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!" to "!drive:$=:!\"
				
				:: without admin rights we cannot write singularly to most drive roots
				REM xcopy /q /i /s /h /y "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!" "!drive:$=:!\" >nul 2>&1
								
				:: check if directory
				if exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o\*" (
					if not exist "!drive:$=:!\%%o" mkdir "!drive:$=:!\%%o"
					
					if exist "!drive:$=:!\%%o" (
						REM echo copying "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" to "!drive:$=:!\%%o"
						xcopy /q /i /s /h /y "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" "!drive:$=:!\%%o" >nul 2>&1
						if %errorlevel% NEQ 0 (
							echo COULD NOT COPY "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" to "!drive:$=:!\%%o"^^!
						)
					) else echo COULD NOT CREATE !drive:$=:!\%%o^^!
				) else (
					REM echo copying "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" to "!drive:$=:!\%%o"
					copy /L /Y "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" "!drive:$=:!\%%o" >nul 2>&1
					if !errorlevel! NEQ 0 (
						REM echo COULD NOT COPY "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" to "!drive:$=:!\%%o"^^!
						if not exist "!drive:$=:!\RootFallback\" mkdir "!drive:$=:!\RootFallback"
						echo fallback copying "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" to "!drive:$=:!\RootFallback\%%o"
						copy /L /Y "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o" "!drive:$=:!\RootFallback\%%o" >nul 2>&1
						
						if !errorlevel! NEQ 0 (
							echo FAILED TO RESTORE "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AllData\!drive!\%%o"
						)
					)
				)
			)
		) else echo A matching drive for !drive! did not exist^^!
	)
	echo COMPLETE^^!
)
endlocal

echo.
echo Preparing to restore AppData...
timeout /t 3 /nobreak >nul 2>&1

:: restore AppData files
set appdir=%AppData:~0,-8%
if exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData\" (
	attrib +h "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData" >nul 2>&1
	echo Copied %USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData to %appdir%
	xcopy /q /s /h /y "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\AppData" "%appdir%"  >nul 2>&1
)

:: leaves breadcrumb file to indicate the script was previously ran
for /f "tokens=*" %%p in ('time /t') DO echo|set/p=[ %%p ] > "%USERPROFILE%\Documents\OneDriveMigration.txt"
date /t >>"%USERPROFILE%\Documents\OneDriveMigration.txt"

echo.
echo.
echo Restoration of profile complete!
echo If any errors occured or something doesn't seem right, please reach out to us.
echo - The IS Team @ Service Desk: 832-824-3512
PAUSE
echo Goodbye