@echo off
REM Wrapper so Windows Task Scheduler can run the bash labeler with clean quoting.
REM %~dp0 resolves to this script's directory (scripts\), so %~dp0.. is the repo root.
SET REPO_DIR=%~dp0..
"C:\Program Files\Git\bin\bash.exe" -lc "%REPO_DIR:\=/%/scripts/nightly-label.sh >> %REPO_DIR:\=/%/scripts/nightly-label.log 2>&1"
