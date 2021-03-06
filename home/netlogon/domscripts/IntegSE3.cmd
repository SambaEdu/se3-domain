﻿:: permet de lancer les scripts de mise au domaine au 2eme reboot
:: le nom est deja change, sauf en cas de clonage ou on le recupere
:: dans action.bat
:: script lance en administrateur local
@echo off
pushd %SystemDrive%\netinst
if not exist logs md logs
time /T >> logs\domscripts.txt
echo demarrage de l'integration a SE3>> logs\domscripts.txt 
echo suppression de adminse3...
TASKKILL /F /T /FI "USERNAME eq adminse3"
ping -n 10 127.0.0.1 >NUL
if exist "%systemDrive%\Documents and settings\adminse3" rd /S /Q "%systemDrive%\Documents and settings\adminse3" && echo profil adminse3 efface
for /d %%i in ("%systemDrive%\Documents and settings\adminse3.*") do rd /S /Q "%%i"
echo initialisation des du reseau... 
call %systemdrive%\netinst\se3ip.bat
:: on attend que le réseau soit actif !
if exist %systemdrive%\netinst\ipfixe.csv call %systemdrive%\netinst\ifconfig.cmd
:: necessaire pour cpau : deux lignes car nom de service different pour XP et Seven.
net start "connexion secondaire" 2>NUL
net start "Ouverture de session secondaire" 2>NUL

:: hack (temporaire on l'espere) pour pouvoir utiliser 10 sur un domaine type NT
ver | findstr /i /c:"version 10." >nul
if "%errorlevel%"=="0" (
	:: on desactive smb2/3
	sc.exe config lanmanworkstation depend= bowser/mrxsmb20/mrxsmb10/nsi
	sc.exe config mrxsmb20 start= disabled
	:: on active smb1
	sc.exe config lanmanworkstation depend= bowser/mrxsmb10/nsi
	sc.exe config mrxsmb10 start= auto
	reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths" /v "\\*\netlogon" /d "RequireMutualAuthentication=0,RequireIntegrity=0,RequirePrivacy=0" /F >NUL
	reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths" /v "\\*\netlogon" /d "RequireMutualAuthentication=0,RequireIntegrity=0,RequirePrivacy=0" /F >NUL
	reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /d "0" /t REG_DWORD /F >NUL
)

ping -n 5 %SE3IP%
:: on efface les GPO 
if exist %systemroot%\system32\grouppolicy rd /S /Q %systemroot%\system32\grouppolicy && echo GPO effacees
:: on efface les profiles adminse3
:: creation d'adminse3 et mise au domaine
echo lancement du job netdom
cmd /c %systemdrive%\netinst\CPAU.exe -wait -dec -lwp -cwd %systemdrive%\ -file %systemdrive%\netinst\netdom.job>> logs\domscripts.txt 
