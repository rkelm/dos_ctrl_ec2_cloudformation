@ECHO OFF
REM Batch file to warn a player not keeping to the rules.
SETLOCAL enabledelayedexpansion

REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als erster Parameter angegeben werden.
  PAUSE
  EXIT /B 1
)

REM Let user type in minecraft user name to add.
ECHO Bitte geben Sie den Minecraft User Namen ein, der bestraft werden soll.
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

IF DEFINED _output (
  SET _SECONDS=120
  SET _AMPLIFIER=10
  
  CALL cf_send_cmd.bat %_CONFIG% app_cmd.sh 'effect give %_output% minecraft:blindness !_SECONDS! !_AMPLIFIER! true' 'effect give %_output% minecraft:mining_fatigue !_SECONDS! !_AMPLIFIER! true' 'effect give %_output% minecraft:weakness !_SECONDS! !_AMPLIFIER! true' 'playsound entity.ghast.hurt master %_output% 1 1 1 5.0 2.0 1.0'
  CALL cf_send_cmd.bat %_CONFIG% app_cmd.sh 'playsound entity.ghast.hurt master %_output% 1 1 1 5.0 2.0 1.0'
  CALL cf_send_cmd.bat %_CONFIG% app_cmd.sh 'playsound entity.ghast.hurt master %_output% 1 1 1 5.0 2.0 1.0'

REM  CALL %CTRL_PATH%ec2_send_command.bat %1 sudo -u ec2-user %SRV_INSTALL_DIR% service minecraft command effect %_output% minecraft:blindness !_SECONDS! !_AMPLIFIER! true
  
REM CALL %CTRL_PATH%ec2_send_command.bat %1 service minecraft command effect %_output% minecraft:mining_fatigue !_SECONDS! !_AMPLIFIER! true
REM  CALL %CTRL_PATH%ec2_send_command.bat %1 service minecraft command effect %_output% minecraft:weakness !_SECONDS! !_AMPLIFIER! true
REM  CALL %CTRL_PATH%ec2_send_command.bat %1 service minecraft command effect %_output% minecraft:slowness !_SECONDS! !_AMPLIFIER! true

) ELSE (
  ECHO Eingabe des Minecraft User Namen war leer. Bestrafung konnte nicht ausgefuehrt werden.
)

PAUSE
REM Restore previous current directory.
CD /D %EXCURRENTDIR%
