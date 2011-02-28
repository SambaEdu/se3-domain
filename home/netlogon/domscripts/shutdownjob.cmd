:: lancee avec un job CPAU au startup par les GPO afin de ne jamais avoir les mdp sensibles sur le DD � un quleconque moment
::
:: $Id: shutdownjob.bat -1M 2009-11-25 23:32:53Z (local) $ 
:: SYNTAXE :
:: shutdownjob.bat  SE3_DOMAIN XPPASS ADMINSE3 COMPUTERNAME
:: 
@echo off

pushd %systemdrive%\netinst
set ADMINSE3=%3%
set XPPASS=%2%
set SE3_DOMAIN=%1%

call action.bat

::netdom.exe verify %computername% /DOMAIN:%SE3_DOMAIN% /userO:%ADMINSE3% /PasswordO:%XPPASS%>> logs\domscripts.txt

echo on quite le domaine %SE3_DOMAIN%>> logs\domscripts.txt
::netdom.exe remove %computername% /D:%SE3_DOMAIN% /userD:%SE3_DOMAIN%\%ADMINSE3% /PasswordD:%XPPASS%>> logs\domscripts.txt
::if errorlevel 1  echo ERREUR en quittant %SE3_DOMAIN%.>> logs\domscripts.txt
start /wait %SystemRoot%\system32\cscript.exe //D quitte_domaine.vbs /u:"%ADMINSE3%" /p:"%XPPASS%">> logs\domscripts.txt
echo shutdownjob OK>> logs\domscripts.txt 
exit
