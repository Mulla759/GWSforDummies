@echo off
REM Windows wrapper for gws-do — runs the bash entry via Git Bash.
REM Usage: gws-do "triage my inbox"
"C:\Program Files\Git\bin\bash.exe" -lc "'%~dp0gws-do' %*"
