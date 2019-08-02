@ECHO OFF
REM Batch file to create package for distribution to users.
SET LOCAL_DIR=dos_ctrl_ec2_cloudformation\
SET BUILD_DIR=build\
SET DSTFILENAME=dos_ctrl_ec2_cloudformation.zip
REM Remember previous current directory.
SET EXCURRENTDIR=%CD%
REM Switch current directory to one level above batch file directory.
CD /D %~dp0
CD ..

ECHO '************ Building %BUILD_DIR%%DSTFILENAME% ************'
COPY %LOCAL_DIR%setup_shortcuts.bat .

REM Add files to control Minecraft instance.
C:\Programme\7-Zip\7z.exe a %LOCAL_DIR%%BUILD_DIR%%DSTFILENAME% @%LOCAL_DIR%build_file_list.txt

IF ERRORLEVEL 1 (
	ECHO Error creating deployment package.
	REM Restore previous current directory.
	CD /D %EXCURRENTDIR%
	EXIT /B 1
) ELSE (
	ECHO Successfully created deployment package.
)

CD %LOCAL_DIR%\build

REM Restore previous current directory.
CD /D %EXCURRENTDIR%

ECHO '************ Successfully created deployment package ************'
PAUSE
