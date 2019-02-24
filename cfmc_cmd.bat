@ECHO OFF
setlocal enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als erster Parameter angegeben werden.
  PAUSE
  EXIT /B 1
)
REM CALL load_config.bat %_CONFIG%

SET _I=0
SET _SERVER_COMMAND=
FOR %%A IN ( %* ) DO (
	REM We dont need the first and second command.
	SET /A _I=!_I! + 1
    IF !_I! GEQ 2 (
		SET _SERVER_COMMAND=!_SERVER_COMMAND! %%A
	)
)

CALL %CTRL_PATH%cf_send_cmd.bat %_CONFIG% app_cmd.sh %_SERVER_COMMAND%

PAUSE
