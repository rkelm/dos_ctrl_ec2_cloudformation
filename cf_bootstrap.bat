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
SET INSTIDFILE=instanceid_%_CONFIG%.txt

REM Load config.
CALL load_config.bat %_CONFIG%
IF ERRORLEVEL 2 EXIT /B 1

REM IF NOT DEFINED VOLUMEID IF NOT DEFINED VOLUMETAGKEY IF NOT DEFINED SNAPSHOTID IF NOT DEFINED SNAPSHOTTAGKEY (
REM 	ECHO In der Konfiguration %_CONFIG% ist weder ein Volume noch ein Snapshot spezifziert.
REM 	ECHO Breche ab.
REM 	EXIT /B 1
REM )

REM Check: "Is the last from this client startet instance still running?"
IF EXIST %INSTIDFILE% (
	REM Load old instance id from file.
	SET INSTANCEID=EMPTY
	SET /P INSTANCEID=<%INSTIDFILE%

	IF NOT [!INSTANCEID!] == [EMPTY] (
		REM Ask aws if this is a known running/pending/shutting-down instance.
		%AWS_BIN% --region %REGION% ec2 describe-instances --filters Name=instance-state-name,Values=running,shutting-down,pending Name=instance-id,Values=!INSTANCEID! --output=text --query Reservations[*].Instances[*].InstanceId > output.txt
		SET OUTPUT=EMPTY
		SET /P OUTPUT=<output.txt
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
	  --output text > ami_image_id.txt

	SET /P IMAGEID=<ami_image_id.txt
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
  --output text

IF ERRORLEVEL 1 (
	ECHO Error creating stack.
	EXIT /B 1
)

REM Wait until stack creation has finished.
ECHO Waiting for end of stack creation...
%AWS_BIN% --region %REGION% cloudformation wait stack-create-complete --stack-name %STACKNAME%-Run

REM Check for error.
ECHO Verifying success...
%AWS_BIN% --region %REGION% cloudformation describe-stacks --stack-name %STACKNAME%-Run ^
  --query Stacks[0].StackId --output text > run-stack.txt
SET /P _STACKID=<run-stack.txt
IF DEFINED _STACKID (
    ECHO Success. Run stack created.
) ELSE (
    ECHO Failed. Run stack not created.
	EXIT /B 1
)

REM EC2 Instanztyp %INSTANCETYPE% 
REM %AWS_BIN% ec2 run-instances --image-id %IMAGEID% --instance-type %INSTANCETYPE% %KEYPAIR_PARAM% %SECURITYGROUPSID_PARAM% --instance-initiated-shutdown-behavior terminate --region %REGION% %SUBNETID_PARAM% %SSM_ROLE_NAME_PARAM% --user-data file://prepare_server.sh --output text --query Instances[*].InstanceId > %INSTIDFILE%
REM SET INSTANCEID=EMPTY
REM SET /P INSTANCEID=<%INSTIDFILE%

REM IF [%INSTANCEID%] == [EMPTY] (
REM 	DEL %INSTIDFILE%
REM 	ECHO Start der Instanz gescheitert.
REM 	EXIT /b 1
REM )

REM ECHO AWS EC2 Instanz startet. (Instance ID %INSTANCEID%)
ECHO %DATE% %TIME% AWS CloudFormation Stack %STACKNAME%-Run Instanz startet. >> dos_ctrl_ec2.log

REM Send notice about starting instance.
REM IF NOT [%SNS_TOPIC_ARN%] == [] (
REM 	%AWS_BIN% sns publish --topic-arn "%SNS_TOPIC_ARN%" --subject "STARTE %APP_NAME% Server auf ec2 Instanztyp %INSTANCETYPE%" --message "Starte %APP_NAME% Server auf %INSTANCETYPE% in Stack %STACKNAME%-Run. (%DATE% %TIME%)" --output text > messageid.txt
REM )REM 

REM Tag Instance for easy identification by 
REM other clients without knowledge of instance id.
REM %AWS_BIN% ec2 create-tags --resources %INSTANCEID% --tags Key=%TAGKEY%,Value=%TAGVALUE%

REM Prepare volume-id.
REM IF DEFINED VOLUMEID (
REM 	SET _VOLUMEID=%VOLUMEID%
REM ) ELSE (
REM 	IF DEFINED VOLUMETAGKEY (
REM 		REM Find ebs volume by tag. 
REM 		%AWS_BIN% ec2 describe-volumes --region %REGION% --filters Name=status,Values=available Name=tag:%VOLUMETAGKEY%,Values=%VOLUMETAGVALUE% --output=text --query Volumes[*].VolumeId > volumeid.txt
        REM Delete volumeid file if it is empty.
REM 		for %%F in ("volumeid.txt") do if %%~zF equ 0 del "%%F"
REM 		IF NOT EXIST volumeid.txt (
REM 			ECHO Kein verfuegbares EBS Volume mit Tag-Name/Value: %VOLUMETAGKEY% / %VOLUMETAGVALUE% gefunden.
REM 			ECHO Der Start einer neuen Instanz wird abgebrochen.
REM 			EXIT /b 1
REM 		)
REM 		SET /P _VOLUMEID=<volumeid.txt
REM 	) ELSE  (
	    REM Get snapshot id to create Volume from snapshot.
REM 		IF DEFINED SNAPSHOTID (
REM 			SET _SNAPSHOT=%SNAPSHOTID%
REM 		) ELSE (
REM 			REM Find snapshot by tag.
REM 			%AWS_BIN% ec2 describe-snapshots --region %REGION% --filters Name=status,Values=completed Name=tag:%SNAPSHOTTAGKEY%,Values=%SNAPSHOTTAGVALUE% --output=text --query Snapshots[*].SnapshotId > snapshotid.txt
REM 			REM Delete snapshotid file if it is empty.
REM 			for %%F in ("snapshotid.txt") do if %%~zF equ 0 del "%%F"
REM 			IF NOT EXIST snapshotid.txt (
REM 				ECHO Kein EBS Snapshot mit Tag-Name/Value: %SNAPSHOTTAGKEY% / %SNAPSHOTTAGVALUE% gefunden.
REM 				ECHO Der Start einer neuen Instanz wird abgebrochen.
REM 				EXIT /b 1
REM 			)
REM 			SET /P _SNAPSHOTID=<snapshotid.txt
REM 		)
        REM Create volume from snapshot.
		REM Get availability zone of configured subnet.
REM 		%AWS_BIN% ec2 describe-subnets --region %REGION% --filter Name=subnet-id,Values=%SUBNETID% --output text --query Subnets[*].AvailabilityZone > availabilityzone.txt
REM 		SET /P _AVAILABILITYZONE=<availabilityzone.txt
REM 		ECHO Erstelle EBS Volume in AvailabilityZone !_AVAILABILITYZONE! aus EBS Snapshot mit Id !_SNAPSHOTID!.
REM 		%AWS_BIN% ec2 create-volume --region %REGION% --availability-zone !_AVAILABILITYZONE! --snapshot-id !_SNAPSHOTID! --volume-type gp2 --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=TEMPORARY_%APP_NAME%}]" --query VolumeId --output text > volumeid.txt
REM 		SET /P _VOLUMEID=<volumeid.txt
REM 		REM Remember we created this volume.
REM 		SET _VOLUMECREATED=TRUE
REM 		ECHO Temporaeres Volume !_VOLUMEID! erstellt.
REM 		)
REM )

REM ECHO Warte auf Abschluss des Instanzstarts ...
REM %AWS_BIN% ec2 wait instance-running --instance-ids %INSTANCEID%
REM %AWS_BIN% ec2 wait instance-running --instance-ids %INSTANCEID%

REM IF NOT DEFINED %_VOLUMEID (
REM 	ECHO Es konnte keine gueltige EBS VolumeId ermittelt werden.
REM 	ECHO Terminiere die gestartete Instanz.
REM 	CALL ec2_terminate.bat %_CONFIG%
REM 	EXIT /B 1
REM )

REM Get ip address.
REM ECHO Frage Verbindungsdaten ab.
REM %AWS_BIN% ec2 describe-instances --instance-ids %INSTANCEID% --output text --query Reservations[*].Instances[*].PublicIpAddress > ipaddress.txt
REM SET /P IPADDRESS=<ipaddress.txt

REM ECHO Die IP-Adresse der Instanz ist %IPADDRESS%

REM Call batch file to update DNS, if configured.
REM IF EXIST %DNSSETUPBATCH% (
REM 	ECHO Aktualisiere DNS %DNSHOSTNAME% auf IP %IPADDRESS%.
REM 	CALL %DNSSETUPBATCH% %DNSHOSTNAME% %IPADDRESS% >> dos_ctrl_ec2.log
REM 	IF ERRORLEVEL 1 ECHO Fehler beim Aktualisieren des DNS. Siehe Logdatei dos_ctrl_ec2.log.
REM )

REM ECHO Instanz erfolgreich gestartet, verbinde mit EBS Laufwerk.
REM %AWS_BIN% ec2 attach-volume --volume-id %_VOLUMEID% --instance-id %INSTANCEID% --device /dev/sdf > attachvolume.json

REM IF ERRORLEVEL 1 (
REM 	ECHO Fehler beim Verbinden der Instanz %_INSTANCEID% mit dem Laufwerk-Volume ID %_VOLUMEID%
REM 	ECHO Terminiere die gestartete Instanz.
REM 	CALL ec2_terminate.bat %_CONFIG%
REM 	EXIT /b 1
REM 	)

REM If this volume was created by this script, then it should be marked to be deleted at instance termination.
REM IF "%_VOLUMECREATED%" == "TRUE" (
REM 	ECHO Markiere temporaeres Volume als "DeleteOnTermination".
REM 	%AWS_BIN% --region %REGION% ec2 modify-instance-attribute --instance-id %INSTANCEID% --block-device-mappings "[{\"DeviceName\": \"/dev/sdf\",\"Ebs\":{\"DeleteOnTermination\":true}}]"
REM 	IF ERRORLEVEL 1 (
REM 		ECHO Fehler beim Markieren des temporaeren Volumes "%_VOLUMEID% mit "DeleteOnTermination".
REM 		)
REM )

IF NOT [%CONNECTION_DATA%] == [] (
	ECHO Verbindungsdaten: %CONNECTION_DATA%
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
