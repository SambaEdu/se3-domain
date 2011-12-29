:: script de mise au domaine manuel
:: fonctionnel sous windows XP et OS ultérieurs mais privilegier rejointSE3.exe.
:: $Id: rejointSE3.cmd 5579 2010-06-01 19:44:08Z dbo $
:: n'est normalement lancee qu'en cas d'adhesion d'un nouveau poste, et que la mise au
:: domaine depuis l'interface se3 a echoue
:: si le poste a deja ete enregistre dans l'interface, le fichier action.bat existe dans machine\ip
::
:: valeur de %netbios_name% renseignee automatiquement, ne pas toucher
set netbios_name=se3
set se3ip=10.211.55.200
::
for /f "tokens=2 delims=[]" %%i in ('nbtstat -a %computername% ^|find "Adresse IP"') do set IP=%%i
::
md %systemdrive%\Netinst
md %systemdrive%\Netinst\logs
net use Z: \\%netbios_name%\netlogon
if errorlevel 1 (
        set netbios_name=se3
        net use Z: \\%netbios_name%\netlogon
)

if errorlevel 1 (
    echo ERREUR : impossible de se connecter au serveur
    echo avant de lancer ce script connectez vous a \\%netbios_name%\netlogon avec le compte adminse3 !
    pause
    exit
    )
copy  /Y z:\domscripts\* %Systemdrive%\Netinst
copy  /Y z:\CPAU.exe %Systemdrive%\Netinst

@echo off
for /f "tokens=3,* delims=	 " %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ProductName" 2^>NUL ^| Find "ProductName"') do (
	echo Systeme d'exploitation: %%a %%b
	set WINVERS=%%a %%b
)
:: pas d'elevation de privilege sous windows XP
echo %WINVERS%| Find "Windows XP" 1>NUL 2>NUL
if "%errorlevel%"=="0" (
	echo Execution de rejointSE3-elevated.cmd sous %WINVERS%.
	call %systemdrive%\Netinst\rejointSE3-elevated.cmd
) ELSE (
	echo Execution en mode eleve de rejointSE3-elevated.cmd sous %WINVERS%.
	cscript %systemdrive%\Netinst\execute-elevated.js %systemdrive%\Netinst\rejointSE3-elevated.cmd
)