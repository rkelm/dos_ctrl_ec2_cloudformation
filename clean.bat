@ECHO OFF
REM Batch file to delete temporary files from directory.

SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

ECHO Deleting temporary files.
IF EXIST prepared-stack.txt DEL prepared-stack.txt
IF EXIST dos_ctrl_ec2.log DEL dos_ctrl_ec2.log
IF EXIST cmd_status.txt DEL cmd_status.txt
IF EXIST commandid.txt DEL commandid.txt
IF EXIST output.txt DEL output.txt
IF EXIST instanceid_TEST.txt DEL instanceid_TEST.txt
IF EXIST cmd_status.txt DEL cmd_status.txt
IF EXIST defaultvpc.txt DEL defaultvpc.txt
IF EXIST job_id.txt DEL job_id.txt
IF EXIST map_ids.txt DEL map_ids.txt
IF EXIST map_ids2.txt DEL map_ids2.txt
IF EXIST prepared-stack.txt DEL prepared-stack.txt
IF EXIST renderjobdef.txt DEL renderjobdef.txt
IF EXIST renderjobqueue.txt DEL renderjobqueue.txt
IF EXIST run-stack.txt DEL run-stack.txt

REM Switching back to previous directory.
CD %EXCURRENTDIR%
