@ECHO OFF
REM Batch file to launch ec2 instance.
SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO [ERROR] Es muss ein Konfigurationskuerzel als Parameter angegeben werden.
  EXIT /B 1
)
REM Load config.
CALL load_config.bat %_CONFIG%
IF ERRORLEVEL 2 EXIT /B 1

REM IF NOT DEFINED VOLUMEID IF NOT DEFINED VOLUMETAGKEY IF NOT DEFINED SNAPSHOTID IF NOT DEFINED SNAPSHOTTAGKEY (
REM 	ECHO In der Konfiguration %_CONFIG% ist weder ein Volume noch ein Snapshot spezifziert.
REM 	ECHO Breche ab.
REM 	EXIT /B 1
REM )

SET INSTIDFILE=%TEMPDIR%instanceid_%_CONFIG%.txt

REM Check: "Is the last from this client startet instance still running?"
IF EXIST %INSTIDFILE% (
	REM Load old instance id from file.
	SET INSTANCEID=EMPTY
	SET /P INSTANCEID=<%INSTIDFILE%

	IF NOT [!INSTANCEID!] == [EMPTY] (
		REM Ask aws if this is a known running/pending/shutting-down instance.
		%AWS_BIN% --region %REGION% ec2 describe-instances --filters Name=instance-state-name,Values=running,shutting-down,pending Name=instance-id,Values=!INSTANCEID! --output=text --query Reservations[*].Instances[*].InstanceId > %TEMPDIR%output.txt
		SET OUTPUT=EMPTY
		SET /P OUTPUT=<%TEMPDIR%output.txt

		IF NOT [!OUTPUT!] == [EMPTY] (
			REM Instance ist still running. Complain to user and exit.
			ECHO Es laeuft bereits eine Instanz von %APP_NAME% !
			ECHO Start einer neuen Instanz wird abgebrochen.
			ECHO Bitte erst die alte Instanz beenden.
			EXIT /b 1
		)
    )
)

REM Check for running instance by searching for tag in aws cloud.
%AWS_BIN% --region %REGION% ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF EXIST %INSTIDFILE% (
  ECHO Es laeuft bereits eine Instanz von %APP_NAME% !
  ECHO Start einer neuen Instanz wird abgebrochen.
  ECHO Bitte erst die alte Instanz beenden.
  EXIT /b 1
)

REM Prepare optional run-instances parameters.
REM IF NOT [%SECURITYGROUPSID%] == [] SET SECURITYGROUPSID_PARAM=--security-group-ids %SECURITYGROUPSID%
REM IF NOT [%SUBNETID%] == [] SET SUBNETID_PARAM=--subnet-id %SUBNETID%
REM IF NOT [%KEYPAIR%] == [] SET KEYPAIR_PARAM=--key-name %KEYPAIR%
REM IF NOT [%SSM_ROLE_NAME%] == [] (
REM 	SET SSM_ROLE_NAME_PARAM=--iam-instance-profile Name=%SSM_ROLE_NAME%
REM )
IF [%IMAGEID%] == [CURRENT] (
	REM If CURRENT ami image id configured, then choose most current available public amazon
	REM linux ami for x86_64 architecture and ebs in chosen aws region. Avoid release
	REM candidate versions.
	ECHO Kein ami Image konfiguriert, suche aktuellstes Image.
    %AWS_BIN% --region %REGION% ec2 describe-images ^
	  --filters Name=root-device-type,Values=ebs Name=architecture,Values=x86_64 Name=virtualization-type,Values=hvm Name=name,Values=amzn-ami-hvm-2*gp2 Name=state,Values=available ^
	  --owners amazon ^
	  --query "Images[?^!contains(Name, '.rc-')]|sort_by(@, &CreationDate)[-1].[ImageId]" ^
	  --output text > %TEMPDIR%ami_image_id.txt

	SET /P IMAGEID=<%TEMPDIR%ami_image_id.txt
)

IF NOT [%IMAGEID%] == [] (
	REM Show image details.
	ECHO Details des ami Images mit der image-id %IMAGEID%:
	%AWS_BIN% --region %REGION% ec2 describe-images --image-id %IMAGEID% --query "Images[].[ImageId, Name, CreationDate, RootDeviceName]" --output text
)

IF DEFINED DNSHOSTNAME (
  REM Add dot to DNSHOSTNAME, if Hostname is configured.
  SET _DNSHOSTNAME=ParameterKey=HostSubdomain,ParameterValue=%DNSHOSTNAME%.

  FOR /F "delims=. tokens=1,*" %%G IN ("%DNSHOSTNAME%.") DO SET _HOSTSUBDOMAIN=%%H
  SET _DNSHOSTNAME=!_DNSHOSTNAME! ParameterKey=MCHostedZoneName,ParameterValue=!_HOSTSUBDOMAIN!
)

REM Launch Amazon Linux Instance. Run prepare_server.sh on server.
ECHO Starte AWS CloudFormation Stack %STACKNAME%-Run fuer %APP_NAME%.
%AWS_BIN% --region %REGION% cloudformation create-stack ^
  --stack-name %STACKNAME%-Run ^
  --template-body file://run-template.json ^
  --parameters ^
  ParameterKey=MapBucket,ParameterValue=%MAP_BUCKET% ^
  ParameterKey=KeyName,ParameterValue=%KEYPAIR% ^
  ParameterKey=InstanceType,ParameterValue=%INSTANCETYPE% %KEYPAIR_PARAM% ^
  ParameterKey=MCLocation,ParameterValue=%MCIPWHITELIST% ^
  ParameterKey=SSHLocation,ParameterValue=%SSHLocation% ^
  ParameterKey=MCPort,ParameterValue=%MCPORT% ^
  ParameterKey=DockerImage,ParameterValue=%SRV_CTRL_IMAGE% ^
  ParameterKey=AMIImageId,ParameterValue=%IMAGEID% ^
  %_DNSHOSTNAME% ^
  ParameterKey=AWSTagKey,ParameterValue=%TAGKEY% ^
  ParameterKey=AWSTagValue,ParameterValue=%TAGVALUE% ^
  ParameterKey=BucketMapDir,ParameterValue=%MAP_S3_KEY% ^
  ParameterKey=StackAlias,ParameterValue=%_CONFIG% ^
  ParameterKey=RConPwd,ParameterValue=%RCONPWD% ^
  --on-failure DELETE ^
  --tags Key=%TAGKEY%,Value=%TAGVALUE% ^
  --output text > nul

IF ERRORLEVEL 1 (
	ECHO [ERROR] Error creating stack.
	EXIT /B 1
)

REM Wait until stack creation has finished.
REM ECHO Waiting for end of stack creation...
%AWS_BIN% --region %REGION% cloudformation wait stack-create-complete --stack-name %STACKNAME%-Run

REM Check for error.
REM ECHO Verifying success...
%AWS_BIN% --region %REGION% cloudformation describe-stacks --stack-name %STACKNAME%-Run ^
  --query Stacks[0].StackId --output text > %TEMPDIR%run-stack.txt
SET /P _STACKID=<%TEMPDIR%run-stack.txt
IF DEFINED _STACKID (
    ECHO [INFO] Success. Run stack created.
) ELSE (
    ECHO [ERROR] Failed. Run stack not created.
	EXIT /B 1
)

REM ECHO AWS EC2 Instanz startet. (Instance ID %INSTANCEID%)
ECHO %DATE% %TIME% AWS CloudFormation Stack %STACKNAME%-Run Stack gestartet. >> dos_ctrl_ec2.log

REM Send notice about starting instance.
IF NOT [%ADMIN_EMAIL%] == [] (
  %AWS_BIN% --region %REGION% cloudformation describe-stacks ^
      --stack-name %STACKNAME%-Prepared ^
      --query "Stacks[0].Outputs[?contains(OutputKey,'SNSTopicArn')].OutputValue" ^
      --output text > %TEMPDIR%sns-arn.txt
  SET /P _SNS_TOPIC_ARN=<%TEMPDIR%sns-arn.txt
 	%AWS_BIN% --region %REGION% sns publish --topic-arn "!_SNS_TOPIC_ARN!" ^
      --subject "STARTE %APP_NAME% Server auf ec2 Instanztyp %INSTANCETYPE%" ^
      --message "Starte %APP_NAME% Server auf %INSTANCETYPE% in Stack %STACKNAME%-Run. (%DATE% %TIME%)" ^
      --output text > %TEMPDIR%messageid.txt
)

IF NOT [%CONNECTION_DATA%] == [] (
	ECHO Verbindungsdaten: %CONNECTION_DATA%
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
