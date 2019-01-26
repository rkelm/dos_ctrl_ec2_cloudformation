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

REM Switching back to previous directory.
CD %EXCURRENTDIR%
