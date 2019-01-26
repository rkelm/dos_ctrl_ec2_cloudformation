@ECHO OFF
REM Batch file to delete temporary files from directory.

SETLOCAL enabledelayedexpansion

REM Remember previous current directory.
SET EXCURRENTDIR=%CD%

REM Switch current directory to installation directory.
CD /D %~dp0

ECHO Deleting temporary files.
IF EXIST prepared-stack.txt DEL prepared-stack.txt


REM Switching back to previous directory.
CD %EXCURRENTDIR%
