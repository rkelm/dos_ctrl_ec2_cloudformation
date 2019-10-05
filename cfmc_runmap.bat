@ECHO OFF
setlocal enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

SET _NOPAUSE=%2

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO [ERROR] Es muss ein Konfigurationskuerzel als erster Parameter angegeben werden.
  PAUSE
  EXIT /B 1
)

CALL load_config.bat %_CONFIG%

REM ECHO Lade aktuelle Map-Liste.
IF NOT DEFINED CURL_BIN (
	ECHO [ERROR] CURL_BIN not configured
	PAUSE
	EXIT /b 1
)
IF NOT EXIST %CURL_BIN% (
	ECHO [ERROR] %CURL_BIN% not found 
	PAUSE
	EXIT /b 1
)

IF NOT DEFINED URL_MAP_ID_FILE (
	ECHO [ERROR] URL_MAP_ID_FILE not configured
	PAUSE
	EXIT /b 1
)

%CURL_BIN% %CURL_OPTIONS% -s %URL_MAP_ID_FILE%  > %TEMPDIR%map_ids.txt
IF ERRORLEVEL 1 (
  ECHO [ERROR] Konnte die Map-Liste nicht von %URL_MAP_ID_FILE% laden.
  PAUSE
  EXIT /B 1
)

SET /P list=<%TEMPDIR%map_ids.txt

:SHOWMENU
ECHO.
ECHO Es stehen folgende Karten zur Auswahl:
ECHO Druecke 1 fuer "Keine Karte starten"
SET i=1
FOR %%x IN (%list%) DO (
	SET /a i=!i!+1
	ECHO Druecke !i! fuer %%x
)
ECHO.
SET /P _input=Bitte Nummer der zu startenden MC Karte eingeben: 

SET map_id=
IF %_input%==1 ( 
	GOTO :RUNMAP 
)

SET i=1
FOR %%x IN (%list%) DO (
	SET /a i=!i!+1
	IF %_input%==!i! (
		SET map_id=%%x
		GOTO :RUNMAP
	)
)
REM Number not found.
ECHO Ungueltige Auswahl!
ECHO.
GOTO :SHOWMENU 

:RUNMAP
IF DEFINED map_id (
	ECHO [INFO] Lade Minecraft Karte %map_id% 
	CALL cf_send_cmd.bat %_CONFIG% run_map.sh %map_id%
) ELSE (
	ECHO [INFO] Keine Karte gewaehlt.
)

IF NOT DEFINED _NOPAUSE (
	PAUSE
)

