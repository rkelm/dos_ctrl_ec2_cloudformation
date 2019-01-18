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
SET CONFIGFILE=config\ec2_config_%_CONFIG%.bat
SET INSTIDFILE=instanceid_%_CONFIG%.txt

REM Check if config file exists. If not complain.
IF NOT EXIST %CONFIGFILE% (
	ECHO Konfigurationsdatei %CONFIGFILE% nicht gefunden.
	EXIT /B 1
	)
	
REM Load configuration variables.
CALL %CONFIGFILE%

IF NOT DEFINED VOLUMEID IF NOT DEFINED VOLUMETAGKEY IF NOT DEFINED SNAPSHOTID IF NOT DEFINED SNAPSHOTTAGKEY (
	ECHO In der Konfiguration %_CONFIG% ist weder ein Volume noch ein Snapshot spezifziert.
	ECHO Breche ab.
	EXIT /B 1
)


REM Check: "Is the last from this client startet instance still running?"
IF EXIST %INSTIDFILE% (
	REM Load old instance id from file.
	SET INSTANCEID=EMPTY
	SET /P INSTANCEID=<%INSTIDFILE%

	IF NOT [!INSTANCEID!] == [EMPTY] (
		REM Ask aws if this is a known running/pending/shutting-down instance.
		aws ec2 describe-instances --filters Name=instance-state-name,Values=running,shutting-down,pending Name=instance-id,Values=!INSTANCEID! --output=text --query Reservations[*].Instances[*].InstanceId > output.txt
		SET OUTPUT=EMPTY
		SET /P OUTPUT=<output.txt
		IF NOT [!OUTPUT!] == [EMPTY] (
			REM Instance ist still running. Complain to user and exit.
			ECHO Es laeuft bereits eine %APP_NAME% Server Instanz!
			ECHO Start einer neuen Instanz wird abgebrochen.
			ECHO Bitte erst die alte Instanz beenden.
			EXIT /b 1
		)
    )
)

REM Check for running instance by searching for tag in aws cloud.
aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:%TAGKEY%,Values=%TAGVALUE% --output=text --query Reservations[*].Instances[*].InstanceId > %INSTIDFILE%
REM Delete instance id file if it is empty.
for %%F in ("%INSTIDFILE%") do if %%~zF equ 0 del "%%F"
IF EXIST %INSTIDFILE% (
  ECHO Es laeuft bereits eine %APP_NAME% Server Instanz!
  ECHO Start einer neuen Instanz wird abgebrochen.
  ECHO Bitte erst die alte Instanz beenden.
  EXIT /b 1
)

REM Prepare optional run-instances parameters.
IF NOT [%SECURITYGROUPSID%] == [] SET SECURITYGROUPSID_PARAM=--security-group-ids %SECURITYGROUPSID%
IF NOT [%SUBNETID%] == [] SET SUBNETID_PARAM=--subnet-id %SUBNETID%
IF NOT [%KEYPAIR%] == [] SET KEYPAIR_PARAM=--key-name %KEYPAIR%
IF NOT [%SSM_ROLE_NAME%] == [] (
	SET SSM_ROLE_NAME_PARAM=--iam-instance-profile Name=%SSM_ROLE_NAME%
)
IF [%IMAGEID%] == [] (
	REM If no ami image id configured, then choose most current available public amazon
	REM linux ami for x86_64 architecture and ebs in chosen aws region. Avoid release
	REM candidate versions.
	ECHO Kein ami Image konfiguriert, suche aktuellstes Image.
    aws ec2 describe-images --region %REGION% --filters Name=root-device-type,Values=ebs Name=architecture,Values=x86_64 Name=virtualization-type,Values=hvm Name=name,Values=amzn-ami-hvm-2*gp2 Name=state,Values=available  --owners amazon --query "Images[?^!contains(Name, '.rc-')]|sort_by(@, &CreationDate)[-1].[ImageId]" --output text > ami_image_id.txt

	SET /P IMAGEID=<ami_image_id.txt
)

REM Exit if image id is invalid.
IF [%IMAGEID%] == [] (
	ECHO Kein gueltiges ami Image gefunden. 
	ECHO Start einer neuen Instanz wird abgebrochen.
	EXIT /b 1
)

REM Show image details.
ECHO Details des ami Images mit der image-id %IMAGEID%:
aws ec2 describe-images --region %REGION% --image-id %IMAGEID% --query "Images[].[ImageId, Name, CreationDate, RootDeviceName]" --output text

REM Launch Amazon Linux Instance. Run prepare_server.sh on server.
ECHO Starte AWS EC2 Instanztyp %INSTANCETYPE% fuer %APP_NAME%.
aws ec2 run-instances --image-id %IMAGEID% --instance-type %INSTANCETYPE% %KEYPAIR_PARAM% %SECURITYGROUPSID_PARAM% --instance-initiated-shutdown-behavior terminate --region %REGION% %SUBNETID_PARAM% %SSM_ROLE_NAME_PARAM% --user-data file://prepare_server.sh --output text --query Instances[*].InstanceId > %INSTIDFILE%
SET INSTANCEID=EMPTY
SET /P INSTANCEID=<%INSTIDFILE%

IF [%INSTANCEID%] == [EMPTY] (
	DEL %INSTIDFILE%
	ECHO Start der Instanz gescheitert.
	EXIT /b 1
)

ECHO AWS EC2 Instanz startet. (Instance ID %INSTANCEID%)
ECHO %DATE% %TIME% AWS EC2 Instanz startet. (Instance ID %INSTANCEID%) >> dos_ctrl_ec2.log

REM Send notice about starting instance.
IF NOT [%SNS_TOPIC_ARN%] == [] (
	aws sns publish --topic-arn "%SNS_TOPIC_ARN%" --subject "STARTE %APP_NAME% Server auf ec2 Instanztyp %INSTANCETYPE%" --message "Starte %APP_NAME% Server auf %INSTANCETYPE% mit Instanz ID %INSTANCEID%. (%DATE% %TIME%)" --output text > messageid.txt
)

REM Tag Instance for easy identification by 
REM other clients without knowledge of instance id.
aws ec2 create-tags --resources %INSTANCEID% --tags Key=%TAGKEY%,Value=%TAGVALUE%

REM Prepare volume-id.
IF DEFINED VOLUMEID (
	SET _VOLUMEID=%VOLUMEID%
) ELSE (
	IF DEFINED VOLUMETAGKEY (
		REM Find ebs volume by tag. 
		aws ec2 describe-volumes --region %REGION% --filters Name=status,Values=available Name=tag:%VOLUMETAGKEY%,Values=%VOLUMETAGVALUE% --output=text --query Volumes[*].VolumeId > volumeid.txt
        REM Delete volumeid file if it is empty.
		for %%F in ("volumeid.txt") do if %%~zF equ 0 del "%%F"
		IF NOT EXIST volumeid.txt (
			ECHO Kein verfuegbares EBS Volume mit Tag-Name/Value: %VOLUMETAGKEY% / %VOLUMETAGVALUE% gefunden.
			ECHO Der Start einer neuen Instanz wird abgebrochen.
			EXIT /b 1
		)
		SET /P _VOLUMEID=<volumeid.txt
	) ELSE  (
	    REM Get snapshot id to create Volume from snapshot.
		IF DEFINED SNAPSHOTID (
			SET _SNAPSHOT=%SNAPSHOTID%
		) ELSE (
			REM Find snapshot by tag.
			aws ec2 describe-snapshots --region %REGION% --filters Name=status,Values=completed Name=tag:%SNAPSHOTTAGKEY%,Values=%SNAPSHOTTAGVALUE% --output=text --query Snapshots[*].SnapshotId > snapshotid.txt
			REM Delete snapshotid file if it is empty.
			for %%F in ("snapshotid.txt") do if %%~zF equ 0 del "%%F"
			IF NOT EXIST snapshotid.txt (
				ECHO Kein EBS Snapshot mit Tag-Name/Value: %SNAPSHOTTAGKEY% / %SNAPSHOTTAGVALUE% gefunden.
				ECHO Der Start einer neuen Instanz wird abgebrochen.
				EXIT /b 1
			)
			SET /P _SNAPSHOTID=<snapshotid.txt
		)
        REM Create volume from snapshot.
		REM Get availability zone of configured subnet.
		aws ec2 describe-subnets --region %REGION% --filter Name=subnet-id,Values=%SUBNETID% --output text --query Subnets[*].AvailabilityZone > availabilityzone.txt
		SET /P _AVAILABILITYZONE=<availabilityzone.txt
		ECHO Erstelle EBS Volume in AvailabilityZone !_AVAILABILITYZONE! aus EBS Snapshot mit Id !_SNAPSHOTID!.
		aws ec2 create-volume --region %REGION% --availability-zone !_AVAILABILITYZONE! --snapshot-id !_SNAPSHOTID! --volume-type gp2 --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=TEMPORARY_%APP_NAME%}]" --query VolumeId --output text > volumeid.txt
		SET /P _VOLUMEID=<volumeid.txt
		REM Remember we created this volume.
		SET _VOLUMECREATED=TRUE
		ECHO Temporaeres Volume !_VOLUMEID! erstellt.
		)
)

ECHO Warte auf Abschluss des Instanzstarts ...
aws ec2 wait instance-running --instance-ids %INSTANCEID%
aws ec2 wait instance-running --instance-ids %INSTANCEID%

IF NOT DEFINED %_VOLUMEID (
	ECHO Es konnte keine gueltige EBS VolumeId ermittelt werden.
	ECHO Terminiere die gestartete Instanz.
	CALL ec2_terminate.bat %_CONFIG%
	EXIT /B 1
)

REM Get ip address.
ECHO Frage Verbindungsdaten ab.
aws ec2 describe-instances --instance-ids %INSTANCEID% --output text --query Reservations[*].Instances[*].PublicIpAddress > ipaddress.txt
SET /P IPADDRESS=<ipaddress.txt

ECHO Die IP-Adresse der Instanz ist %IPADDRESS%

REM Call batch file to update DNS, if configured.
IF EXIST %DNSSETUPBATCH% (
	ECHO Aktualisiere DNS %DNSHOSTNAME% auf IP %IPADDRESS%.
	CALL %DNSSETUPBATCH% %DNSHOSTNAME% %IPADDRESS% >> dos_ctrl_ec2.log
	IF ERRORLEVEL 1 ECHO Fehler beim Aktualisieren des DNS. Siehe Logdatei dos_ctrl_ec2.log.
)

ECHO Instanz erfolgreich gestartet, verbinde mit EBS Laufwerk.
aws ec2 attach-volume --volume-id %_VOLUMEID% --instance-id %INSTANCEID% --device /dev/sdf > attachvolume.json

IF ERRORLEVEL 1 (
	ECHO Fehler beim Verbinden der Instanz %_INSTANCEID% mit dem Laufwerk-Volume ID %_VOLUMEID%
	ECHO Terminiere die gestartete Instanz.
	CALL ec2_terminate.bat %_CONFIG%
	EXIT /b 1
	)

REM If this volume was created by this script, then it should be marked to be deleted at instance termination.
IF "%_VOLUMECREATED%" == "TRUE" (
	ECHO Markiere temporaeres Volume als "DeleteOnTermination".
	aws ec2 modify-instance-attribute --instance-id %INSTANCEID% --block-device-mappings "[{\"DeviceName\": \"/dev/sdf\",\"Ebs\":{\"DeleteOnTermination\":true}}]"
	IF ERRORLEVEL 1 (
		ECHO Fehler beim Markieren des temporaeren Volumes "%_VOLUMEID% mit "DeleteOnTermination".
		)
)

IF NOT [%CONNECTION_DATA%] == [] (
	ECHO Verbindungsdaten: %CONNECTION_DATA%
)

REM Restore previous current directory.
CD /D %EXCURRENTDIR%
