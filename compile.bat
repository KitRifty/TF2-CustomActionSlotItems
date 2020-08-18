@echo off

set SRCROOT=%1
for /f "useback tokens=*" %%a in ('%SRCROOT%') do set SRCROOT=%%~a
set DESTROOT=%2
for /f "useback tokens=*" %%a in ('%DESTROOT%') do set DESTROOT=%%~a
xcopy "%SRCROOT%\scripting" "%DESTROOT%\scripting" /s /y
xcopy "%SRCROOT%\gamedata" "%DESTROOT%\gamedata" /s /y
xcopy "%SRCROOT%\translations" "%DESTROOT%\translations" /s /y
cd "%DESTROOT%\scripting"

cls

set SCRIPT=actionslotitems
spcomp.exe %SCRIPT%.sp -o "..\plugins\%SCRIPT%.smx"

