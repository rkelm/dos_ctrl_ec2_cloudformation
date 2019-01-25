REM @ECHO OFF
REM ******* Configuration ******* 

REM Enter path and file name to AWS crendentials batch file here. (Optional)
REM The referenced batch file should set the aws environment variables
REM AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
REM If a credentials file is not provided aws credentials must be 
REM configured and provided otherwise.
REM Example: SET CREDENTIALSFILE=%USERPROFILE%\.aws\apprunner_credentials.bat
SET CREDENTIALSFILE=

REM Load your AWS credentials into environment variables, if credentials file exists.
IF NOT [%CREDENTIALSFILE%] == [] (
 	IF EXIST "%CREDENTIALSFILE%" (
		CALL "%CREDENTIALSFILE%"
		)
	)

REM 

REM Location to find the remote configuration file. If it begins with s3:
REM the aws s3 cli is used, if it begins with http curl is used,
REM else it is considered a local file (Required)
REM If no or a relative path is specified, the path is considered 
REM relative to the installation directory.
REM (Watch out for uppper and lowercase with s3.)
REM Example: SET REMOTE_CONFIG_PATH=s3://mybucket/
REM          SET REMOTE_CONFIG_FILE=remote_config.bat
REM Example: SET REMOTE_CONFIG_PATH=http://mywebspace.com/
REM          SET REMOTE_CONFIG_FILE=remote_config.bat
REM Example: SET REMOTE_CONFIG_PATH=
REM          SET REMOTE_CONFIG_FILE=remote_config.bat
SET REMOTE_CONFIG_PATH=
SET REMOTE_CONFIG_FILE=

REM Set path to aws command, if not in path. In some installations 
REM a CALL must be added. (required)
REM Example SET AWS_BIN=CALL aws
REM Example SET AWS_BIN=aws
SET AWS_BIN=CALL aws

REM Set path to curl binary. Needed for downloading a remote
REM configuration file via http. The path may be relative to this
REM tools installation path. (optional)
REM Example SET CURL_BIN=utils\curl.exe
SET CURL_BIN=utils\curl.exe
