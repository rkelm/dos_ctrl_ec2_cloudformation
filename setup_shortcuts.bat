@ECHO OFF
SETLOCAL enabledelayedexpansion

SET REPO_DIR=dos_ctrl_ec2_cloudformation

ECHO Dieser Batch erstellt in diesem Verzeichnis Verknuepfungen zu den Batch Dateien und benennt diese. Sie muss im Verzeichnis oberhalb von %REPO_DIR% ausgefuehrt werden.

SET _DIR=%~dp0

REM Are we in the right directory?
IF EXIST %_DIR%cfmc_launch.bat (
	REM We dont need to use a subdirectory.
	SET _BAT_DIR=
) ELSE (
	IF NOT EXIST %_DIR%%REPO_DIR%\cfmc_launch.bat (
		ECHO Konnte zu verknuepfende Dateien weder unter %_DIR% noch unter %_DIR%%_BAT_DIR% finden
		ECHO Breche ab.
		PAUSE
		EXIT /B 1
	)
	SET _BAT_DIR=%REPO_DIR%
)

ECHO Bitte geben Sie das Kuerzel der zu verwendenden %REPO_DIR% Konfigurationsdatei ein.
SET /P _input=

REM This remove-unwanted-chars-in-string solution was shared by jeb on stack overflow. Thank you!
set "_output="
set "map=abcdefghijklmnopqrstuvwxyz1234567890_"

:loop
if not defined _input goto endLoop    
for /F "delims=*~ eol=*" %%C in ("!_input:~0,1!") do (
    if "!map:%%C=!" NEQ "!map!" set "_output=!_output!%%C"
)
set "_input=!_input:~1!"
    goto loop
:endLoop

IF NOT DEFINED _output (
	ECHO Sie haben keinen gueltigen Wert fuer das Kuerzel eingegeben.
	EXIT /B 1
	PAUSE
)

REM SET _TARGET_FILE=cfmc_cmd.bat
REM SET _LINK_NAME=Server Command
REM powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%';$s.Save()"

SET _TARGET_FILE=cfmc_kick.bat
SET _LINK_NAME=Kick Spieler vom Server
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_launch.bat
SET _LINK_NAME=STARTE Server
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_punish.bat
SET _LINK_NAME=Bestrafe Spieler
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_rendermap.bat
SET _LINK_NAME=Kartenuebersicht aktualisieren
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_runmap.bat
SET _LINK_NAME=Karte laden
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_savemap.bat
SET _LINK_NAME=Karte speichern
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_terminate.bat
SET _LINK_NAME=BEENDE Server
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_whitelist_add.bat
SET _LINK_NAME=Spieler zur Whitelist hinzufuegen
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_whitelist_list.bat
SET _LINK_NAME=Namen auf der Whitelist anzeigen
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

SET _TARGET_FILE=cfmc_whitelist_remove.bat
SET _LINK_NAME=Namen von der Whitelist entfernen
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%_DIR%\EC2 MC %_LINK_NAME% %_output%.lnk');$s.TargetPath='%_DIR%%_BAT_DIR%\%_TARGET_FILE%'; $s.Arguments='%_output%'; $s.WorkingDirectory='%_DIR%%_BAT_DIR%'; $s.Save()"

ECHO Verknuepfungen wurden erstellt und koennen jetzt ins Zielverzeichnis verschoben werden.

PAUSE
