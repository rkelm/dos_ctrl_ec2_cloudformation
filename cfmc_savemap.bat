@ECHO OFF
REM Batch file to save the currently running map without stopping it.
SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
SET _MAP_ID=%2
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als erster Parameter angegeben werden.
  PAUSE
  EXIT /B 1
)

ECHO Speichere aktuelle Karte.
CALL cf_send_cmd.bat %_CONFIG% save_map.sh

PAUSE

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
