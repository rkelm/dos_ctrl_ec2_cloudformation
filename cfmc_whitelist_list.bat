@ECHO OFF
REM Batch file to list whitelisted user on EC2 Minecraft Server.
SETLOCAL enabledelayedexpansion
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

ECHO Rufe Whitelist des Minecraft Servers ab.
CALL cf_send_cmd.bat %_CONFIG% app_cmd.sh 'whitelist list'
 
PAUSE
