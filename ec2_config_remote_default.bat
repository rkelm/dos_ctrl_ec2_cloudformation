REM @ECHO OFF
REM ******* Configuration ******* 

REM     ***** Configuration of Prepare Batch START *****

REM If any one of the following values is changed, the prepare batch
REM must be run again.
REM Edit here to setup script for your environment.

REM Choose aws region. (Required)
REM All required resources will be created in the same region.
SET REGION=eu-central-1

REM Name of the CloudFormation Stack to create. The name must be
REM unique within the chosen aws region and your aws account. (Required)
SET STACKNAME=MY_MC_STACK

REM This mailadress may receive SNS notifications about some 
REM admin events on the server. (Required)
SET ADMIN_EMAIL=admin@example.com

REM The name of the NON PUBLIC S3 bucket used to save the MC map files.
REM This bucket must not contain any data other than that for this server.
REM (Required)
SET MAP_BUCKET=MC-DATA

REM     ***** Configuration of Prepare Batch END *****
REM S3 Prefix for storing maps. (Required)
SET MAP_S3_KEY=maps/

REM S3 Prefix for storing maps. (Required)
SET LOGS_S3_KEY=logs/

REM Choose aws instance type. Typical instance types are c4.large, 
REM t2.medium, t2.small, t2.micro. (Required)
SET INSTANCETYPE=t2.small

REM Tags for other clients to discover a running instance. (Required)
REM Must be unique to safely identify the running instance!
SET TAGKEY=MC-SERVER
SET TAGVALUE=VANILLA

REM Dynamic DNS host name for the server. Please end it with a dot.
REM (Required)
SET DNSHOSTNAME=my-ec2-server.example.com

REM Http URL to download file with map_ids to choose from in docmc_runmap.bat
REM (Required.)
SET URL_MAP_ID_FILE=https://s3.eu-central-1.amazonaws.com/my-mc-bucket/map_ids.txt

REM The full docker image name from the image to load. This image should
REM be built and uploaded to ECR in the selected region. (Required)
REM Example: SET SRV_CTRL_IMAGE='aws account no'.dkr.ecr.eu-central-1.amazonaws.com/mc_srv_ctrl:0.1
SET SRV_CTRL_IMAGE=

REM TCP Port to accept MC client connections on. The default is 25565
REM (Required)
SET MCPORT=25565

REM IP netmask client white list for connecting to MC server.
REM 0.0.0.0/0 allows all IPv4 addresses. (Required)
SET MCIPWHITELIST=0.0.0.0/0

REM IP netmask client white list for connecting to SSH server.
REM 0.0.0.0/0 allows all IPv4 addresses. (Required)
SET SSHLocation=0.0.0.0/0


REM Optional name of the app run on ec2. Used in messages. (Optional)
SET APP_NAME=my_app

REM Optional text shown at launch to user, for example hostname:port.
REM (Optional)
SET CONNECTION_DATA=%DNSHOSTNAME%

REM Set Image ID for root device of instance. (Optional)
REM If left blank, a default amazon linux AMI will be chosen. 
REM Example: SET IMAGEID=ami-f9619996
SET IMAGEID=

REM Name of EC2 Keypair for SSH Public Key Login. (Optional)
REM Example: KEYPAIR=Power_User
SET KEYPAIR=Power_User

