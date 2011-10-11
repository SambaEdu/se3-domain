:: ce script est lance par cpau en admine3 et connait les variables d'environnement :

:: Il permet :
:: 1. d'installer les outils de registre se3
:: 2. d'installer wpkg sans le lancer puis de lancer l'install complete des applis wpkg lors du reboot suivant
:: 3. de lancer des installations et commandes personnalisees eventuelles contenues dans \\se3\install\scripts\perso.bat
:: 4. de lancer wpkg pour installer les applications qui doivent etre presentes sur "Touslespostes"
:: 5. d'installer OCS inventory et de remonter un rapport immediatement.

@echo off

:: 1. preparation a SAMBAEDU3
echo ############ PREPARATION DU POSTE POUR SE3 ###########################
pushd %SystemDrive%\netinst
echo Nettoyage des fichiers wpkg si presents
if exist %systemroot%\wpkg.txt del /F /Q %systemroot%\wpkg.txt && echo Suppression de wpkg.txt
if exist %systemroot%\wpkg.log del /F /Q %systemroot%\wpkg.log && echo Suppression de wpkg.log
if exist %systemroot%\wpkg-client.vbs del /F /Q %systemroot%\wpkg-client.vbs && echo Suppression de wpkg-client.vbs
if exist %systemroot%\system32\wpkg.xml del /F /Q %systemroot%\system32\wpkg.xml && echo Suppression de wpkg.xml
echo.
echo ############### PREPARATION DU DERNIER DEMARRAGE #########################
echo.
echo Au prochain reboot : on demarrera sur le domaine %SE3_DOMAIN%, pas "sur ce poste"...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" /d "%SE3_DOMAIN%" /F >NUL
echo.
echo Nettoyage du login automatique 
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /F >NUL
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /F >NUL
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /F >NUL

::Permet d'eviter d'avoir a changer d'utilisateur lors du premier login sur windows seven
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" /v "LastLoggedOnUser" /F >NUL 2>NUL
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" /v "LastLoggedOnSAMUser" /F >NUL 2>NUL

ping -n 5 127.0.0.1>NUL
echo On efface la cle run qui a ete ajoutee par base.bat au reboot d'avant.
reg.exe delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SE3install" /F >NUL
echo ########## FIN DE LA PREPARATION DU DERNIER DEMARRAGE #############################
echo.
:: cachedlogonscount = 0
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "CachedLogonsCount" /d "0" /F >NUL
echo On vire ces saloperies de fichiers hors connexion...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache" /v "Formatdatabase" /t "REG_DWORD" /d "1" /F >NUL
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache" /v "Enabled" /t "REG_DWORD" /d "0" /F >NUL

echo Securisation du compte Administrateur : "wawa" n'est pas tres secure meme si le chef n'est pas d'accord.
if exist %systemdrive%\localpw.job (
    start /wait %systemdrive%\netinst\CPAU.exe -wait -dec -lwp -cwd %SystemDrive%\ -file %SystemDrive%\netinst\localpw.job
) else (	
    net user administrateur %XPPASS% >NUL
)
net accounts /maxpwage:unlimited


echo ##### FIN DE LA PREPARATION DU POSTE POUR SE3 ##########################
echo.

echo Mappage de la lettre Z: vers \\%NETBIOS_NAME%\install
:: Pour une utilisation aisee des scripts wpkg lances par perso.bat

if "%Z%"=="" set Z=Z:>NUL
if "%SOFTWARE%"=="" set SOFTWARE=Z:\packages>NUL
if "%ComSpec%"=="" set ComSpec=%SystemRoot%\system32\cmd.exe>NUL
net use Z: \\%NETBIOS_NAME%\install /user:adminse3 %XPPASS% >NUL
call %Z%\wpkg\initvars_se3.bat >NUL

if exist Z:\scripts\perso.bat (
    echo ########### LANCEMENT D'INSTRUCTIONS PERSONNELLES ######################
    call Z:\scripts\perso.bat
    echo ############### FIN DES INSTRUCTIONS PERSONNELLES ######################
) ELSE (
    echo Pas de commande personnaliseea lancer : pas de script Z:\scripts\perso.bat
)

@if "%OS%"=="Windows_NT" (
    echo Sur windows 2000-XP, on impose "no_driver_signing" sur tous les postes
    if exist "%Z%\scripts\fra\no_driver_signing.exe" start /wait cmd /c "%Z%\scripts\fra\no_driver_signing.exe"&ping -n 10 127.0.0.1>NUL
) else (
    bcdedit.exe -set loadoptions DISABLE_INTEGRITY_CHECKS
)

echo ############## INSTALLATION WPKG ENCHAINEE #########
:: on verifie si wpkg est deja installe : si c'est le cas , c'est qu'il s'agit d'un clonage ou renommage.
if exist %SystemRoot%\wpkg-client.vbs goto dejawpkg
    :: sinon, il s'agit d'une install unattended et que wpkg est installe => installation des programmes wpkg prevus pour "_Touslespostes"
    if exist %SystemDrive%\netinst\DOIT.BAT if exist z:\wpkg\wpkg-se3.js cscript z:\wpkg\wpkg-se3.js /profile:unattended /synchronize /nonotify
:dejawpkg
:: (re) installer la tache wpkg sans la lancer 
echo Installation de la tache planifiee wpkg sans execution immediate
Set NoRunWpkgJS=1
Set TaskUser=adminse3
Set TaskPass=%XPPASS%
if exist Z:\wpkg\wpkg-install.bat call Z:\wpkg\wpkg-install.bat

echo.
echo WPKG SERA LANCE AU PROCHAIN REBOOT
echo ################## FIN DE L'INSTALLATION WPKG ###############

echo.
echo ######## Installation d'ocsinventory si present sur le se3 ############
:: 1. stopper service, 2. remplacer le fichier ini pour fixer une remontee rapide apres 2sec, 3. redemarrer le service => remontee d'un rapport immediat
set OCSINI=%ProgramFiles%\OCS Inventory Agent\service.ini
if exist %NETBIOS_NAME%\Progs\ro\inventory\deploy\ocs.bat (
    call %NETBIOS_NAME%\Progs\ro\inventory\deploy\ocs.bat
    echo Fichier ini d'OCS : %OCSINI%
    net stop "OCS INVENTORY SERVICE" >NUL
    Copy "%OCSINI%" %systemdrive%\FILEOCSINI.TMP >NUL
    echo Modification du parametre TTO_WAIT pour remontee de l'inventaire dans 2 sec.
    type %systemdrive%\FILEOCSINI.TMP | Findstr /V /I "\<TTO_WAIT"  > "%OCSINI%"
    Del %systemdrive%\FILEOCSINI.TMP  >NUL
    echo TTO_WAIT=2 >> "%OCSINI%"
    echo Redemarrage du service OCS
    net start "OCS INVENTORY SERVICE" >NUL
)


echo Suppression des raccourcis Activeperl
%Z%\wpkg\tools\reg.exe query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Common Programs" | find /I "Common Programs" > %SystemDrive%\tmp.txt
CHCP 1252 > NUL
for /F "tokens=2* delims=	" %%a in (%SystemDrive%\tmp.txt) do (
    CHCP 850 > NUL
    if exist "%%b" set MenuDemarrer=%%b&& echo Le menu demarrer de AllUsers est dans %%b
)
if exist "%MenuDemarrer%\ActivePerl 5.10.0 Build 1004" rd /S /Q "%MenuDemarrer%\ActivePerl 5.10.0 Build 1004"

echo ########## NETTOYAGE DES FICHIERS INUTILES : driver pack, scripts unattended ###########
echo.
echo Suppression des fichiers job devenus inutiles
del /f /q %SystemDrive%\netinst\netdom.job

echo Nettoyage des fichiers necessaires au driver pack
if exist "%systemdrive%\OEM" rd /s /q "%systemdrive%\OEM"
if exist "%systemdrive%\DPSFNSHR.INI" del /F /Q "%systemdrive%\DPSFNSHR.INI"
if exist "%systemdrive%\DPsFnshr.exe" del /F /Q "%systemdrive%\DPsFnshr.exe"

echo Nettoyage des drivers qui prennent de la place...
if exist "%systemdrive%\D" rd /s /q "%systemdrive%\D"

echo Nettoyage des fichiers unattended devenus inutiles
if exist %SystemDrive%\netinst\permcred.bat del /F /Q %SystemDrive%\netinst\permcred.bat
if exist %SystemDrive%\netinst\tempcred.bat del /F /Q %SystemDrive%\netinst\tempcred.bat
if exist %SystemDrive%\netinst\DOIT.BAT del /F /Q %SystemDrive%\netinst\DOIT.BAT
if exist %SystemDrive%\netinst\IntegSE3.cmd del /F /Q %SystemDrive%\netinst\IntegSE3.cmd
if exist %SystemDrive%\netinst\MAPCD.JS del /F /Q %SystemDrive%\netinst\MAPCD.JS
if exist %SystemDrive%\netinst\MAPZNRUN.BAT del /F /Q %SystemDrive%\netinst\MAPZNRUN.BAT
if exist %SystemDrive%\netinst\netdom.exe del /F /Q %SystemDrive%\netinst\netdom.exe
if exist %SystemDrive%\netinst\POSTINST.BAT del /F /Q %SystemDrive%\netinst\POSTINST.BAT
if exist %SystemDrive%\netinst\se3netdom.cmd del /F /Q %SystemDrive%\netinst\se3netdom.cmd
if exist %SystemDrive%\netinst\UNATTEND.TXT del /F /Q %SystemDrive%\netinst\UNATTEND.TXT
if exist %SystemDrive%\netinst\action.bat del /F /Q %SystemDrive%\netinst\action.bat
echo.
echo ############### Fin du nettoyage des fichiers inutiles : DP, unattended #################
echo.



:: remontee du succes de l'operation : y=succes total
if exist "%Systemdrive%\netinst\wget.exe" (
    call "%Systemdrive%\netinst\se3rapport.cmd" post y
    del /F /Q "%Systemdrive%\netinst\se3rapport.cmd"
) ELSE (
    echo Cas impossible en theorie : script de remontee des rapports absent.
    pause
)

echo se3 OK>> domscripts.txt 
