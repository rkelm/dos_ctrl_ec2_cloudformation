@ECHO OFF
REM Batch file to create an AWS Batch Job to render a minecraft map. 
SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

SET _CONFIG=%1
SET _MAP_ID=%2
IF NOT DEFINED _CONFIG (
  ECHO Es muss ein Konfigurationskuerzel als erster Parameter angegeben werden.
  PAUSE
  EXIT /B 1
)

REM Load config.
CALL load_config.bat %_CONFIG%
IF ERRORLEVEL 2 EXIT /B 1

REM *** Check configuration.
REM IF NOT DEFINED BATCH_RENDER_JOB_QUEUE ( 
REM 	ECHO Konfigurationsvariable BATCH_RENDER_JOB_QUEUE nicht definiert.
REM 	EXIT /B 1
REM )
REM IF NOT DEFINED BATCH_RENDER_JOB_DEFINITION ( 
REM 	ECHO Konfigurationsvariable BATCH_RENDER_JOB_DEFINITION nicht definiert.
REM 	EXIT /B 1
REM )
IF NOT DEFINED BATCH_RENDER_JOB_NAME ( 
	ECHO Konfigurationsvariable BATCH_RENDER_JOB_NAME nicht definiert.
	EXIT /B 1
)

IF DEFINED _MAP_ID (
	GOTO :RUNMAP
)
REM *** Choose minecraft map.
REM Load mc map list.
ECHO Lade aktuelle Map-Liste.
IF NOT DEFINED CURL_BIN (
	ECHO CURL_BIN not configured
	PAUSE
	EXIT /b 1
)
IF NOT EXIST %CURL_BIN% (
	ECHO %CURL_BIN% not found 
	PAUSE
	EXIT /b 1
)

IF NOT DEFINED URL_MAP_ID_FILE (
	ECHO URL_MAP_ID_FILE not configured
	PAUSE
	EXIT /b 1
)

%CURL_BIN% %CURL_OPTIONS% -s %URL_MAP_ID_FILE%  > map_ids.txt
IF ERRORLEVEL 1 (
  ECHO Konnte die Map-Liste nicht von %URL_MAP_ID_FILE% laden.
  PAUSE
  EXIT /B 1
)

SET /P list=<map_ids.txt


:SHOWMENU
ECHO.
ECHO Es stehen folgende Karten zur Auswahl:
ECHO Druecke 1 fuer "Keine Karte starten"
SET i=1
FOR %%x IN (%list%) DO (
	SET /a i=!i!+1
	ECHO Druecke !i! fuer %%x
)
ECHO.
SET /P _input=Bitte die Nummer der MC Karte fuer die Uebersichterzeugung eingeben: 

SET _map_id=
IF %_input%==1 ( 
	GOTO :RUNMAP 
)

SET i=1
FOR %%x IN (%list%) DO (
	SET /a i=!i!+1
	IF %_input%==!i! (
		SET _map_id=%%x
		GOTO :RUNMAP
	)
)
REM Number not found.
ECHO Ungueltige Auswahl!
ECHO.
GOTO :SHOWMENU 

:RUNMAP
IF NOT DEFINED _map_id (
	ECHO Keine Karte gewaehlt.
	ECHO Es wird keine Übersicht erzeugt.
	PAUSE
	EXIT /B 0
)

ECHO Erzeuge Uebersicht fuer Minecraft Karte %_map_id% 

SET _BATCH_RENDER_JOB_NAME=%BATCH_RENDER_JOB_NAME%_%_map_id%

REM Get name of render job definition.
%AWS_BIN% --region %REGION% cloudformation describe-stacks --stack-name %STACKNAME%-Prepared ^
  --query Stacks[0].Outputs[?ExportName=='MCRenderJobDefinition-%_CONFIG%'].OutputValue --output text > renderjobdef.txt
SET /P _BATCH_RENDER_JOB_DEFINITION=<renderjobdef.txt

REM Get name of render job queue.
%AWS_BIN% --region %REGION% cloudformation describe-stacks --stack-name %STACKNAME%-Prepared ^
  --query Stacks[0].Outputs[?ExportName=='MCRenderJobQueue-%_CONFIG%'].OutputValue --output text > renderjobqueue.txt
SET /P _BATCH_RENDER_JOB_QUEUE=<renderjobqueue.txt

REM *** Create AWS Batch Job.
aws batch submit-job --region %REGION% ^
					 --job-name %_BATCH_RENDER_JOB_NAME% ^
                     --job-queue %_BATCH_RENDER_JOB_QUEUE% ^
                     --job-definition %_BATCH_RENDER_JOB_DEFINITION%  ^
					 --container-overrides "command=render_map.sh,%_map_id%" ^
					 --query "jobId" --output text > job_id.txt
REM --parameters KeyName1=string,KeyName2=string

REM *** Show success or failure message.
IF NOT ERRORLEVEL 1 (
	ECHO Batch Job %_BATCH_RENDER_JOB_NAME% mit JobId %_JOBID% erstellt.
) ELSE (
	ECHO Batch Job Erstellung fehlgeschlagen.
	GOTO END
)

SET /P _JOBID=<job_id.txt


ECHO Aktualisierung der Karte %_map_id% gestartet. Das kann bis zu 30 Minuten dauern.
ECHO Das Ergebnis kann spaeter unter %URL_MAP_OVERVIEW% eingesehen werden.

:END
PAUSE
