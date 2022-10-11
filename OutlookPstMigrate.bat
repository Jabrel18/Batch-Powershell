@echo OFF

if exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files" exit /b 1
if not exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files" mkdir "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files"

if [%~1]==[] ( for /f %%h in ('hostname') DO if not defined HOST SET "HOST=%%h" ) else ( SET "HOST=%~1" )

setlocal EnableDelayedExpansion

if not exist "\\tccdav1b\Global\scouting\!HOST!" mkdir "\\tccdav1b\Global\scouting\!HOST!"
echo|set/p=>"\\tccdav1b\Global\scouting\!HOST!\%username%-psts.txt"

for /f %%c in (%~dp0rez\outlook.catalogs) DO (
	for /f "tokens=*" %%e in ('reg query "%%c" 2^>nul ^| findstr /I ".pst"') DO (
		echo %%e>>"\\tccdav1b\Global\scouting\!HOST!\%username%-psts.txt"
		SET "rez=%%e"
		SET "rez=!rez:    =;!"
		for /f "tokens=1,2,3 delims=;" %%p in ("!rez!") DO (
			if exist "%%p" (
				SET "pDir=%%~dpp"
				echo %%~dp | findstr "G: H: S:"
				if !errorlevel! EQU 0 (
					echo %%~p exists on the network and will need to be remapped manually!
					if not exist "\\tccdav1b\Global\scouting\NETDRIVE_PSTS\!HOST!" mkdir "\\tccdav1b\Global\scouting\NETDRIVE_PSTS\!HOST!"
					echo %%p;%%q;%%r>>"\\tccdav1b\Global\scouting\NETDRIVE_PSTS\!HOST!\%username%-remote-psts.txt"
				) else (
					if not exist "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files\!pDir::=$!" ( 
						mkdir "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files\!pDir::=$!"
						REM hack to create parent directories but allow for link
						rmdir "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files\!pDir::=$!"
					)
					echo %%p -^> %USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files\!pDir::=$!%%~nxp>>"\\tccdav1b\Global\scouting\!HOST!\%username%-psts.txt"
					mklink /J "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files\!pDir::=$!" "!pDir!" >nul 2>&1
					
					if /I "%~2"=="REMAP" (
						echo Remapping %%p...
						reg delete "%%c" /V "%%p" /F >nul 2>&1
						reg add "%%c" /V "%USERPROFILE%\OneDrive - Texas Children's\WSS-onedrive-migration\Outlook Files\!pDir::=$!%%~nxp" /T %%q /D %%r
					)
				)
			)
		)
	)
)

endlocal
exit /b 0