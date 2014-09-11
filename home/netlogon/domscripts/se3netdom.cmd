:: Integration au SE3_DOMAIN : lancee avec un job CPAU afin de ne jamais avoir les mdp sensibles sur le DD a un quleconque moment
:: lancee au reboot apres le clonage, les actions et noms, ip sont recuperees dans des fichiers
:: $$Id: se3netdom.cmd -1M 2009-11-25 23:32:53Z (local) $$ 
:: SYNTAXE :
:: se3netdom.cmd %SE3_DOMAIN% %XPPASS% %ADMINSE3%
@echo off

set ADMINSE3=%2%
set XPPASS=%3%
set SE3_DOMAIN=%1%

pushd %SystemDrive%\netinst

call se3ip.bat

if exist action.bat call action.bat

time /T
echo ACTION=%ACTION%

if "%ACTION%"=="clone" goto clone
if "%computername%"=="clone" goto clone
echo suppression de adminse3
net localgroup Administrateurs | findstr adminse3 && net localgroup Administrateurs adminse3 /delete
net user | findstr adminse3 >NUL && net user  adminse3 /delete
net accounts /maxpwage:unlimited
echo creation de adminse3
net user adminse3 %XPPASS% /add
net localgroup Administrateurs adminse3 /add

:: le poste a deja un nom quand on est a cette etape
echo Integration de %Computername% au domaine %SE3_DOMAIN%
:: pour Seven
reg.exe add "HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "DomainCompatibilityMode" /t REG_DWORD /d "1" /F
reg.exe add "HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "DNSNameResolutionRequired" /t REG_DWORD /d "0" /F
reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v "ForceGuest" /t REG_DWORD /d "0" /F 2>NUL
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system" /v "LocalAccountTokenFilterPolicy" /t REG_DWORD /d 1 /f

:: a refaire pour seven en vbs
cscript //D joindomain.vbs /d:"%SE3_DOMAIN%" /p:"%XPPASS%"
::netdom.exe join %computername% /D:%SE3_DOMAIN% /userD:%SE3_DOMAIN%\%ADMINSE3% /PasswordD:%XPPASS%
if errorlevel 1 (
   echo ERREUR LORS DE LA JONCTION A %SE3_DOMAIN%.
   echo Remontee du rapport d'echec sur le SE3.
   call "%Systemdrive%\netinst\se3rapport.cmd" PBnetdom post
   pause
   exit
)
echo Nettoyage du fichier unattend.txt
if exist unattend.txt del /F /Q unattend.txt
echo Preparation du prochain reboot  l'ordinateur a deja integre le SE3_DOMAIN
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SE3install" /d "%SystemDrive%\netinst\Etapefinale.cmd" /F
set NAME=%computername%
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /d "adminse3" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /d "%XPPASS%" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /d "1" /F >NUL
goto suite

:clone
    :: 1ere etape : changer le nom
    :: recuperation fichier unattend.csv si il n'existe pas deja(clonage manuel) 
    set NAME=
    if exist unattend.csv goto dejacsv
		net use Z: \\%SE3IP%\install /user:adminse3 %XPPASS% >NUL
		copy /y z:\site\unattend.csv unattend.csv
		net use * /delete /y
    :dejacsv
	:: recuperation du couple mac nom dans unattend.csv 
	for /f "delims=-, tokens=1-6" %%A in ('getmac /fo:csv /nh') do (
		for /f "tokens=3 delims=," %%N in ('findstr %%A%%B%%C%%D%%E%%F  %systemdrive%\netinst\unattend.csv ^| findstr ComputerName') do (
			echo mac: %%A%%B%%C%%D%%E%%F name : %%~N
			set NAME=%%~N
		)
	)
    :: si on n'a rien recupere il faut demander le nom a l'utilisateur
    if "x%NAME%"=="x" set /P NAME=Entrez le nom du poste :
    if "%NAME%"=="clone" set /P NAME=ERREUR : le poste ne peut etre nomme clone, entrez un autre nom :
    :: changement de nom pas de newsid ???? 
    :: newsid /a %NAME%
    echo renommage de %computername% en %name%
    REG.exe ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" /v ComputerName /t REG_SZ /d "%NAME%" /F
    REG.exe ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "NV Hostname" /t REG_SZ /d "%NAME%" /F
    ::
    :: on reboote pour la mise au domaine
    echo clonage : remommage en %NAME%
    echo set ACTION=rejoint> action.bat

:suite
if exist %SystemDrive%\netinst\shutdown.cmd del /F /Q %SystemDrive%\netinst\shutdown.cmd
if exist %SystemDrive%\netinst\shutdownjob.cmd del /F /Q %SystemDrive%\netinst\shutdownjob.cmd
if exist %SystemDrive%\netinst\shutdown.job del /F /Q %SystemDrive%\netinst\shutdown.job
if exist %SystemRoot%\system32\grouppolicy\machine\scripts\shutdown\shutdown.cmd del /F /Q %SystemRoot%\system32\grouppolicy\machine\scripts\shutdown\shutdown.cmd

echo Au prochain reboot : on demarrera sur ce poste %NAME%, pas sur le SE3_DOMAIN...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" /d "%NAME%" /F >NUL
echo Redemarrage immediat de l ordi
%systemroot%\system32\shutdown.exe -r -t 1 -c "Windows est pret : les programmes vont s'installer au prochain reboot"
echo netdom.job %ACTION% %NAME% OK
