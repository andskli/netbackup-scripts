:: Windows wrapper for netbackup-scripts

@echo off

:: Set perl binary to use
set perlbin="C:\Program Files\VERITAS\VRTSPerl\bin\perl.exe"

if not exist %perlbin% (
  echo %perlbin% does not exist, exiting
  set err=1
  exit /B %err%
)

:: Set which script to access
set command=%*

if exist "%1" (
  echo %1 exists, using %perlbin% to execute

  :: Execute
  echo Executing %perlbin% %*
  %perlbin% %*

  :: Grab exit status of command
  set err=%errorlevel%
  exit /B %err%
) else (
  echo File not found.
  echo %1
  set err=1
  exit /B %err%
)