@ECHO OFF
REM Batch file to unprepare the server launch. 
REM Needs to be run only once to delete the prapred stack created
REM by the prepare_server.bat script.
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

REM Load config.
CALL load_config.bat %_CONFIG%

IF ERRORLEVEL 2 EXIT /B 1

REM Load credentials for user with extended privileges.
IF NOT [%CREDENTIALSFILE_EXTENDED%] == [] (
 	IF EXIST "%CREDENTIALSFILE_EXTENDED%" (
		CALL "%CREDENTIALSFILE_EXTENDED%"
		)
	)

ECHO ### Remember to remove the stack policies from aws users and aws user groups before ###
ECHO ### running this script, else deleting stack will fail. ###
REM Delete prepared CloudFormation Stack
ECHO Deleting prepared stack...
%AWS_BIN% --region %REGION% cloudformation delete-stack --stack-name %STACKNAME%-Prepared ^
  --output text

REM Wait until stack deletion has finished.
ECHO Waiting for end of stack delete...
%AWS_BIN% --region %REGION% cloudformation wait stack-delete-complete --stack-name %STACKNAME%-Prepared

REM Check for error.
ECHO Verifying success...
%AWS_BIN% --region %REGION% cloudformation describe-stacks --stack-name %STACKNAME%-Prepared --query Stacks[0].StackId --output text > prepared-stack.txt 2> nul
SET /P _STACKID=<prepared-stack.txt
IF DEFINED _STACKID (
    ECHO Failed. Prepared stack still exists.
) ELSE (
    ECHO Success. Prepared stack does not exist.
)

cd %EXCURRENTDIR%
