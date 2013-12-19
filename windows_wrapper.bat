:: Windows wrapper for netbackup-scripts
@echo off

:: params for where to find NBU installdir on windows
setlocal ENABLEEXTENSIONS
set NBU_KEY_NAME=HKEY_LOCAL_MACHINE\SOFTWARE\VERITAS\NetBackup\CurrentVersion
set NBU_VALUE_NAME=INSTALLDIR
:: find installdir for netbackup
for /F "skip=2 tokens=1,2*" %%A in ('REG QUERY %NBU_KEY_NAME% /v %NBU_VALUE_NAME% 2^>nul') do (
    set NBU_INSTALLDIR=%%C
)

if defined NBU_INSTALLDIR (
  REM echo NBU INSTALLDIR: %NBU_INSTALLDIR%
  setx NBU_INSTALLDIR "%NBU_INSTALLDIR%" >NUL
) else (
  set err=1
  @echo "%NBU_KEY_NAME%"\"%NBU_VALUE_NAME%" not found.
  exit /B %err%
)

:: params for how to find VRTSPerl installation dir
set VRTSPERL_KEY_NAME=HKEY_LOCAL_MACHINE\SOFTWARE\VERITAS\VRTSPerl
set VRTSPERL_VALUE_NAME=InstallDir
:: find VRTSPerl installdir
for /F "skip=2 tokens=1,2*" %%A in ('REG QUERY %NBU_KEY_NAME% /v %NBU_VALUE_NAME% 2^>nul') do (
  set VRTSPERL_INSTALLDIR=%%C
)

if defined VRTSPERL_INSTALLDIR (
  set PERLBIN="%VRTSPERL_INSTALLDIR%\VRTSPerl\bin\perl.exe"
  ) else (
  set err=1
  @echo "%VRTSPERL_KEY_NAME%"\"%NBU_VALUE_NAME%" not found.
  exit /B %err%
  )

:: Set which script to access
set command=%*

if exist "%1" (
  REM echo %1 exists, using %PERLBIN% to execute

  REM Execute
  REM echo Executing %PERLBIN% %*
  %PERLBIN% %*

  REM Grab exit status of command
  set err=%errorlevel%
  exit /B %err%
) else (
  echo File not found.
  echo %1
  set err=1
  exit /B %err%
)