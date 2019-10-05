@ECHO OFF
REM Batch file to delete temporary files from directory.

SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0
SET TEMPDIR=%~dp0temp\

ECHO Deleting temporary files.
IF EXIST %TEMPDIR%prepared-stack.txt DEL %TEMPDIR%prepared-stack.txt
IF EXIST %TEMPDIR%dos_ctrl_ec2.log DEL %TEMPDIR%dos_ctrl_ec2.log
IF EXIST %TEMPDIR%cmd_status.txt DEL %TEMPDIR%cmd_status.txt
IF EXIST %TEMPDIR%commandid.txt DEL %TEMPDIR%commandid.txt
IF EXIST %TEMPDIR%output.txt DEL %TEMPDIR%output.txt
IF EXIST %TEMPDIR%instanceid_TEST.txt DEL %TEMPDIR%instanceid_TEST.txt
IF EXIST %TEMPDIR%cmd_status.txt DEL %TEMPDIR%cmd_status.txt
IF EXIST %TEMPDIR%defaultvpc.txt DEL %TEMPDIR%defaultvpc.txt
IF EXIST %TEMPDIR%job_id.txt DEL %TEMPDIR%job_id.txt
IF EXIST %TEMPDIR%map_ids.txt DEL %TEMPDIR%map_ids.txt
IF EXIST %TEMPDIR%map_ids2.txt DEL %TEMPDIR%map_ids2.txt
IF EXIST %TEMPDIR%prepared-stack.txt DEL %TEMPDIR%prepared-stack.txt
IF EXIST %TEMPDIR%renderjobdef.txt DEL %TEMPDIR%renderjobdef.txt
IF EXIST %TEMPDIR%renderjobqueue.txt DEL %TEMPDIR%renderjobqueue.txt
IF EXIST %TEMPDIR%run-stack.txt DEL %TEMPDIR%run-stack.txt
IF EXIST %TEMPDIR%messageid.txt DEL %TEMPDIR%messageid.txt
IF EXIST %TEMPDIR%sns-arn.txt DEL %TEMPDIR%sns-arn.txt

REM Switching back to previous directory.
CD %EXCURRENTDIR%
