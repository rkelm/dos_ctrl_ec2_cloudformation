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
REM else it is considered a local file
REM Example: SET REMOTE_CONFIG=s3://mybucket/remote_config
REM Example: SET REMOTE_CONFIG=http://mywebspace.com/remote_config
REM Example: SET REMOTE_CONFIG=C:\remote_config
SET REMOTE_CONFIG=
