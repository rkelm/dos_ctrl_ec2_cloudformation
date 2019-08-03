@ECHO OFF
REM Batch file to launch ec2 instance.
SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%
REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als Parameter angegeben werden.
  EXIT /B 1
)

REM SET INSTIDFILE=instanceid_%CONFIG%.txt

REM Load config.
CALL load_config.bat %_CONFIG%
IF ERRORLEVEL 2 EXIT /B 1

REM Check command line paramters.
SET _APP_CMD=%2
IF NOT DEFINED _APP_CMD (
	REM Complain about missing parameter.
	ECHO Bitte geben sie ein Kommando als zweiten Parameter an.
	EXIT /B 1
)

REM Prepare server command.
SET _I=0
SET _SERVER_COMMAND=
FOR %%A IN ( %* ) DO (
	REM We dont need the first and second command.
	SET /A _I=!_I! + 1
    IF !_I! GEQ 2 (
		SET _SERVER_COMMAND=!_SERVER_COMMAND! %%A
	)
)
REM Add docker exec to send command to srv_ctrl container.
SET _SERVER_COMMAND=docker exec -t base-container %_SERVER_COMMAND%

REM ECHO _SERVER_COMMAND %_SERVER_COMMAND%
SET _INSTIDFILE=instanceid_%_CONFIG%.txt

REM Check for running instance by searching for tag in aws cloud.
%AWS_BIN% --region %REGION%  %ec2 describe-instances ^
  --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% ^
  --output=text ^
  --query Reservations[*].Instances[*].InstanceId > %_INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%_INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF NOT EXIST %_INSTIDFILE% (
  ECHO Es laeuft keine %APP_NAME% Server Instanz!
  ECHO Kommando kann nicht ausgefuehrt werden.
  ECHO Bitte erst eine Instanz starten.
  EXIT /b 1
)
SET /P _INSTANCEID=<%_INSTIDFILE%

REM Send command.
REM %AWS_BIN% --region %REGION% ssm send-command --instance-ids %_INSTANCEID% --document-name "AWS-RunShellScript" --parameters commands="%_SERVER_COMMAND%" --output text --query Command.CommandId > commandid.txt

%AWS_BIN% --region %REGION% ssm send-command --instance-ids %_INSTANCEID% ^
  --document-name "AWS-RunShellScript" ^
  --parameters "{\"commands\":[\"%_SERVER_COMMAND%\"]}" ^
  --query Command.CommandId > commandid.txt

SET /P COMMANDID=<commandid.txt

REM Wait till command execution terminates.
:CMD_EXECUTION
%AWS_BIN% --region %REGION% ssm list-command-invocations --command-id "%COMMANDID%" ^
  --detail --query CommandInvocations[*].Status ^
  --output text > cmd_status.txt
SET /P status=<cmd_status.txt
IF [%STATUS%]==[InProgress] (
	TIMEOUT /T 1 /NOBREAK > nul
	GOTO CMD_EXECUTION
)

IF [%STATUS%] == "Success" (
	REM Get command output.
	%AWS_BIN% --region %REGION% ssm list-command-invocations --command-id "%COMMANDID%" ^
	  --detail --query CommandInvocations[*].CommandPlugins[*].Output ^
	  --output text			
) ELSE (
	%AWS_BIN% --region %REGION% ssm list-command-invocations --command-id "%COMMANDID%" ^
	  --detail --query CommandInvocations[*].CommandPlugins[*].Output ^
	  --output text		
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
