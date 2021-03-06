@ECHO OFF
REM Batch file to terminate ec2 instance.
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

REM Stopping and saving current map.
CALL cf_send_cmd.bat %_CONFIG% stop_map.sh

REM Delete "run" CloudFormation Stack
ECHO Deleting running stack %STACKNAME%-Run...
%AWS_BIN% --region %REGION% cloudformation delete-stack --stack-name %STACKNAME%-Run ^
  --output text

REM Wait until stack deletion has finished.
REM Waiting for end of stack delete...
%AWS_BIN% --region %REGION% cloudformation wait stack-delete-complete ^
  --stack-name %STACKNAME%-Run

REM Check for error.
REM Verifying success...
%AWS_BIN% --region %REGION% cloudformation describe-stacks ^
  --stack-name %STACKNAME%-Run ^
  --query Stacks[0].StackId --output text > %TEMPDIR%prepared-stack.txt 2> nul
SET /P _STACKID=<%TEMPDIR%prepared-stack.txt
IF DEFINED _STACKID (
    ECHO Failed. Run stack may still exist.
) ELSE (
    ECHO Success. Run stack has been deleted.
    REM Send notice about starting instance.
    IF NOT [%ADMIN_EMAIL%] == [] (
      %AWS_BIN% --region %REGION% cloudformation describe-stacks ^
          --stack-name %STACKNAME%-Prepared ^
          --query "Stacks[0].Outputs[?contains(OutputKey,'SNSTopicArn')].OutputValue" ^
          --output text > %TEMPDIR%sns-arn.txt
      SET /P _SNS_TOPIC_ARN=<%TEMPDIR%sns-arn.txt
	    %AWS_BIN% --region %REGION% sns publish --topic-arn "!_SNS_TOPIC_ARN!" ^
        --subject "BEENDE %APP_NAME% Server mit Instanz ID %INSTANCEID%" ^
        --message "Beende %APP_NAME% Server mit Instanz ID %INSTANCEID%. (%DATE% %TIME%)" ^
        --output text > %TEMPDIR%messageid.txt
    )
)


REM Check for running instance by searching for tag in aws cloud.
REM ECHO Suche Instanzen mit Tag %TAGKEY% = %TAGVALUE% und Status running.
REM %AWS_BIN% ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %TEMPDIR%%INSTIDFILE%
REM Delete instance id file if it is empty.
REM FOR %%F IN ("%INSTIDFILE%") DO IF %%~zF equ 0 DEL "%%F"
REM IF NOT EXIST %INSTIDFILE% (
REM 	ECHO Es laeuft keine %APP_NAME% Instanz, die beendet werden koennte.
REM 	EXIT /B 1
REM )

REM SET /P INSTANCEID=<%TEMPDIR%%INSTIDFILE%

REM Terminate instance.
REM ECHO Beende AWS EC2 Instanz mit ID %INSTANCEID%.
REM %AWS_BIN% ec2 terminate-instances --instance-ids %INSTANCEID% > %TEMPDIR%terminate.json

REM ECHO %DATE% %TIME% Beende AWS EC2 Instanz mit ID %INSTANCEID% >> dos_ctrl_ec2.log

REM Wait for end of Termination.
REM ECHO Warte auf Abschluss der Terminierung ...
REM %AWS_BIN% ec2 wait instance-terminated --instance-ids %INSTANCEID%

REM IF NOT ERRORLEVEL 1 (
REM 	ECHO Die Instanz ist terminiert.
REM 	REM Send notice about terminated instance.
REM 	IF NOT [%SNS_TOPIC_ARN%] == [] (
REM 		%AWS_BIN% sns publish --topic-arn "%SNS_TOPIC_ARN%" --subject "BEENDE %APP_NAME% Server mit Instanz ID %INSTANCEID%" --message "Beende %APP_NAME% Server mit Instanz ID %INSTANCEID%. (%DATE% %TIME%)" --output text > %TEMPDIR%messageid.txt
REM 	)
REM )

REM IF [%1] == [] (
REM 	IF EXIST instanceid_bak.txt (
		REM DEL instanceid_bak.txt
REM 	)
REM 	RENAME instanceid.txt instanceid_bak.txt
REM ) ELSE (
REM 	IF EXIST instanceid_bak_%1.txt (
REM 		DEL instanceid_bak_%1.txt
REM 	)
REM 	RENAME instanceid_%1.txt instanceid_bak_%1.txt
REM )

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
