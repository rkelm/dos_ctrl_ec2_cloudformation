@ECHO OFF
REM Batch file to launch EC2 instance with Minecraft Server for running docker app.
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

REM Launch ec2 instance.
CALL cf_bootstrap.bat %_CONFIG%
IF ERRORLEVEL 1 (
  PAUSE
  EXIT /B 1
  )

echo Warte auf Ende der App Installation.
TIMEOUT /T 10 /NOBREAK > nul

REM Run map.
cfmc_runmap.bat %_CONFIG%

REM Restore previous current directory.
CD /D %EXCURRENTDIR%

PAUSE
