@ECHO OFF
REM Batch file to terminate an EC2 instance.

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

ECHO Stop and save running map.
CALL cf_send_cmd.bat %_CONFIG% stop_map.sh

ECHO Terminating ec2 instance.
CALL cf_delete.bat %_CONFIG%

PAUSE

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
