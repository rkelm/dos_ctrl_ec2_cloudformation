@ECHO OFF
REM Batch file to prepare the server launch. 
REM Needs to be run only once. Run unprepare_server.bat
REM to undo the changes and before running this script 
REM again.
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

REM Upload CloudFormation Templates
REM %AWS_BIN% --region %REGION% s3 cp prepare-template.json s3://%MAP_BUCKET%/prepare-template.json
REM %AWS_BIN% --region %REGION% s3 cp run-template.json s3://%MAP_BUCKET%/run-template.json

REM Create prepared CloudFormation Stack
ECHO Creating prepared stack...
%AWS_BIN% --region %REGION% cloudformation create-stack --stack-name %STACKNAME%-Prepared ^
  --template-body file://prepare-template.json ^
  --parameters ParameterKey=MCMapBucketName,ParameterValue=%MAP_BUCKET% ^
    ParameterKey=MCSNSEmailAddress,ParameterValue=%ADMIN_EMAIL% ^
  --capabilities CAPABILITY_IAM --on-failure DELETE ^
  --tags Key=%TAGKEY%,Value=%TAGVALUE% ^
  --output text

REM Wait until stack creation has finished.
ECHO Waiting for end of stack creation...
%AWS_BIN% --region %REGION% cloudformation wait stack-create-complete --stack-name %STACKNAME%-Prepared

REM Check for error.
ECHO Verifying success...
%AWS_BIN% --region %REGION% cloudformation describe-stacks --stack-name %STACKNAME%-Prepared --query Stacks[0].StackId --output text > prepared-stack.txt
SET /P _STACKID=<prepared-stack.txt
IF DEFINED _STACKID (
    ECHO Success. Prepared stack created.
) ELSE (
    ECHO Failed. Prepared stack not created.
)

cd %EXCURRENTDIR%
