:: Windows wrapper for netbackup-scripts

@echo off

:: Set perl binary to use
set perlbin="C:\Program Files\VERITAS\VRTSPerl\bin\perl.exe"

:: Set which script to access
set command=%*

if exist "%1" (
  echo %1 exists, using %perlbin% to execute

  :: Execute
  %perlbin% %*

  :: Grab exit status of command
  set err=%errorlevel%
) else (
  echo File not found.
  echo %1
  set err=1
)
  
:: Exit and pass along our exit code.
exit /B %err%