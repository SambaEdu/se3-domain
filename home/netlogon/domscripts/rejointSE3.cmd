:: script de mise au domaine manuel
:: $Id: rejointSE3.cmd 5579 2010-06-01 19:44:08Z dbo $
:: n'est normalement lanc� qu'en cas d'adh�sion d'un nouveau poste, et que la mise au
:: domaine depuis l'interface se3 a �chou�
:: si le poste a deja ete enregistre dans l'interface, le fichier action.bat existe dans machine\ip
::
:: valeur de %netbios_name% renseign�e automatiquement, ne pas toucher
set netbios_name=
set se3ip=
::
for /f "tokens=2 delims=[]" %%i in ('nbtstat -a %computername% ^|find "Adresse IP"') do set IP=%%i
::
md %systemdrive%\Netinst
md %systemdrive%\Netinst\logs
net use Z: \\%netbios_name%\netlogon
if errorlevel 1 (
        set netbios_name=%se3ip%
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
if exist z:\machine\%IP%\action.bat goto action
    for /f "delims==- tokens=2-7" %%a in ('nbtstat -a %computername% ^|find "Adresse MAC"')  do @set mac=%%a%%b%%c%%d%%e%%f
    :: saloperie de dos !
    set MACADDR=%mac:~1%
    echo Adresse MAC de la carte ayant servi a l'install  : %MACADDR%
    :: recuperation du nom de la machine
    if not exist %systemdrive%\netinst\unattend.csv goto nounattend
    for /f "tokens=3 delims=," %%a in ('findstr %MACADDR% %systemdrive%\netinst\unattend.csv ^| findstr ComputerName') do set NAME=%%~a
    :: si on n'a rien recupere il faut demander le nom a l'utilisateur
    :nounattend
    if "x%NAME%"=="x" (
        cls
	    set /P NAME=entrez le nom de la machine :
	)
    echo la machine va etre mise au domaine sous le nom %NAME%
    echo set ACTION=renomme> %SystemDrive%\Netinst\action.bat
    echo set NAME=%NAME%>> %SystemDrive%\Netinst\action.bat
goto fin
:action
    copy /y z:\machine\%IP%\action.bat %systemdrive%\netinst
:fin
if exist z:\machine\%IP%\localpw.job (
    copy /y z:\machine\%IP%\localpw.job %systemdrive%\netinst
)
else (
    :passwd
	cls
	echo Pour imposer a Administrateur le mot de passe d'adminse3, valider directement par Entree.
        set /P LOCALPW=Si vous souhaitez conserver le mot de passe existant pour le compte Administrateur, confirmez ce mot de passe :
	if "%LOCALPW%x" == "x" goto shutdown
	net use \\%computername%\c$ /user:%computername%\administrateur %LOCALPW%
	if errorlevel 1 goto newpassword
        net use \\%computername%\c$ /delete
        goto passwordok
        :newpassword
                set /P PWOK=Le mot de passe ne correspond pas au mot de passe adminstrateur actuel. Voulez vous le conserver [oN] :
        	if "%PWOK%" != "o" goto passwd
        :passwordok
       	start /wait %Systemdrive%\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file %Systemdrive%\Netinst\localpw.job  -lwp -c -ex "net user administrateur %LOCALPW%"
)
:shutdown
call %systemdrive%\Netinst\shutdown.cmd

