@ECHO OFF
REM Batch file called from other batches to load configuration.

SET _CONFIG=%1
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als Parameter angegeben werden.
  EXIT /B 1
)

REM Remember previous current directory.
SET CONFIGDIR=%~dp0config\

REM Load local config.
SET _CONFIGFILE=%CONFIGDIR%%_CONFIG%_config_local.bat

REM ECHO %_CONFIGFILE%
REM Check if local config file exists. If not complain.
IF NOT EXIST %_CONFIGFILE% (
	ECHO Konfigurationsdatei %_CONFIGFILE% nicht gefunden.
	EXIT /B 1
	)

REM Load configuration variables.
CALL %_CONFIGFILE%

IF NOT DEFINED REMOTE_CONFIG_FILE (
  ECHO Es muss ein Wert fuer REMOTE_CONFIG_FILE in der lokalen Konfigurationsdatei angegeben werden.
  EXIT /B 1
)

REM Must remote config be downloaded?
SET _FIRSTCHARS=%REMOTE_CONFIG_PATH:~0,5%
REM ECHO %REMOTE_CONFIG_PATH%
REM ECHO _FIRSTCHARS %_FIRSTCHARS%

IF %_FIRSTCHARS%==s3:// GOTO check_cache
IF %_FIRSTCHARS%==http: GOTO check_cache
GOTO remote_config_is_local

:check_cache
ECHO Checking for cached remote config file.
REM Create directory for caching configs.
IF NOT EXIST config\cached mkdir config\cached

REM Delete cached files older than 1 day.
FORFILES /P config\cached /M %REMOTE_CONFIG_FILE% /D +1 /C "echo del @file" 2> nul

IF EXIST config\cached\%REMOTE_CONFIG_FILE% GOTO load_cached_config_file

IF %_FIRSTCHARS%==s3:// GOTO s3_download
IF %_FIRSTCHARS%==http: GOTO http_download

:s3_download
REM Download fresh remote config file from s3.
ECHO Downloading remote config file from s3 into cache.

%AWS_BIN% s3 cp --quiet %REMOTE_CONFIG_PATH%%REMOTE_CONFIG_FILE% config\cached\%REMOTE_CONFIG_FILE%
IF ERRORLEVEL 1 (
	ECHO Could not download remote configuration file %REMOTE_CONFIG_PATH%%REMOTE_CONFIG_FILE%
    GOTO:eof
	) 
GOTO load_cached_config_file

:http_download
ECHO Downloading remote config file with http into cache.
REM Download from HTTP.
REM Check for curl.
IF NOT EXIST %CURL_BIN% (
	ECHO %CURL_BIN% not found 
	EXIT /b 1
)

%CURL_BIN% -kso config\cached\%REMOTE_CONFIG_FILE% %REMOTE_CONFIG_PATH%%REMOTE_CONFIG_FILE%
IF ERRORLEVEL 1 (
	ECHO Could not download remote configuration file %REMOTE_CONFIG_PATH%%REMOTE_CONFIG_FILE%
    GOTO:eof
	) 

:load_cached_config_file
ECHO Loading cached config file 
CALL config\cached\%REMOTE_CONFIG_FILE%


GOTO:end

:remote_config_is_local
REM Load remote config from local file.
ECHO Loading local file of remote config.
CALL %REMOTE_CONFIG_PATH%%REMOTE_CONFIG_FILE%

:end
IF ERRORLEVEL 2 EXIT /B 2