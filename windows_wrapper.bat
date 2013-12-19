:: Windows wrapper for netbackup-scripts
@echo off

:: params for where to find NBU installdir on windows
setlocal ENABLEEXTENSIONS
set KEY_NAME=HKEY_LOCAL_MACHINE\SOFTWARE\VERITAS\NetBackup\CurrentVersion
set VALUE_NAME=INSTALLDIR
:: Set perl binary to use
set PERLBIN="C:\Program Files\VERITAS\VRTSPerl\bin\perl.exe"


for /F "skip=2 tokens=1,2*" %%A in ('REG QUERY %KEY_NAME% /v %VALUE_NAME% 2^>nul') do (
    set NBU_INSTALLDIR=%%C
)

if defined NBU_INSTALLDIR (
  REM echo NBU INSTALLDIR: %NBU_INSTALLDIR%
  setx NBU_INSTALLDIR "%NBU_INSTALLDIR%" >NUL
) else (
  set err=1
  @echo "%KEY_NAME%"\"%VALUE_NAME%" not found.
  exit /B %err%
)


if not exist %PERLBIN% (
  echo %PERLBIN% does not exist, exiting
  set err=1
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