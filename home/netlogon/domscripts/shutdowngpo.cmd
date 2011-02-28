:: Integration au SE3_DOMAIN : destine a etre lance au premier reboot par les GPO machine
:: 
:: $Id:$ 
:: SYNTAXE :
:: shutdowngpo.cmd 
:: 
@echo off

pushd %systemdrive%\netinst

:: on prepare le lancement du script de sortie domaine au reboot

reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SE3install" /d "%SystemDrive%\netinst\shutdown.cmd" /F >NUL

:: reboot en tant qu'administrateur, mdp defini par integse3.sh.
:: Normalement cela fonctionne avec ce compte, vu qu'il a permis la
:: connexion sur c$ ?
set ADMIN=
set PASSWD=

echo Au prochain reboot : on demarrera sur ce poste %name%, pas sur le SE3_DOMAIN...
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" /d "%computername%" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /d "%ADMIN%" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /d "%PASSWD%" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /d "1" /F >NUL

if exist %systemroot%\system32\grouppolicy\machine\scripts\startup\startup.cmd del /f /q %systemroot%\system32\grouppolicy\machine\scripts\startup\startup.cmd && echo GPO efface
echo Redemarrage immediat
echo shutdown gpo OK>> logs\domscripts.txt 


