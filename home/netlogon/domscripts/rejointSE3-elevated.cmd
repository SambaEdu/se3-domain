@echo off

:: script lance par executed-elevated.js afin d'élever suffisamment les privilèges
:: sur windows vista ou 7 pour passer les commandes suivantes :


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
	echo "%LOCALPW%x" == "x"
	if "%LOCALPW%x" == "x" goto shutdown
	net use \\%computername%\c$ /user:%computername%\administrateur %LOCALPW%
	if errorlevel 1 goto newpassword
        net use \\%computername%\c$ /delete
        goto passwordok
        :newpassword
                set /P PWOK=Le mot de passe ne correspond pas au mot de passe adminstrateur actuel. Voulez vous le conserver [oN] :
        	if not "%PWOK%" == "o" goto passwd
        :passwordok
       	start /wait %Systemdrive%\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file %Systemdrive%\Netinst\localpw.job  -lwp -c -ex "net user administrateur %LOCALPW%"
)
:shutdown
call %systemdrive%\Netinst\shutdown.cmd


pause