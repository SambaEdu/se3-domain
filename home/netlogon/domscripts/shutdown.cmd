:: Integration au SE3_DOMAIN : destine a etre lance au deuxieme reboot
:: dans le cas d'un demarrage gpo, ou direct par rejointse3.cmd
:: 
:: $Id:$ 
:: SYNTAXE :
:: shutdown.cmd 
:: 
@echo off



:: Passer DEBUG a 1 pour mettre des pauses dans le deroulement du script
set DEBUG=0

:: On fait le menage wpkg : on tue les processus en cours, on supprime la cle wpkg running true, on supprime les fichiers wpkg et on supprime la tache planifiee
TASKKILL /F /FI "USERNAME eq adminse3" /IM cscript.exe
:: on attend un peu le temps que les processus soient coupes
ping -n 10 127.0.0.1 >NUL
reg.exe delete "HKEY_LOCAL_MACHINE\SOFTWARE\WPKG" /v "running" /F >NUL
echo Nettoyage des fichiers wpkg si presents
if exist %systemroot%\wpkg.txt del /F /Q %systemroot%\wpkg.txt && echo Suppression de wpkg.txt
if exist %systemroot%\wpkg.log del /F /Q %systemroot%\wpkg.log && echo Suppression de wpkg.log
if exist %systemroot%\wpkg-client.vbs del /F /Q %systemroot%\wpkg-client.vbs && echo Suppression de wpkg-client.vbs
if exist %systemroot%\system32\wpkg.xml del /F /Q %systemroot%\system32\wpkg.xml && echo Suppression de wpkg.xml
if exist %systemroot%\tasks\wpkg.job del /F /Q %systemroot%\tasks\wpkg.job && echo Suppression de la tache planifiee wpkg

:: on efface les GPO : sauvage mais efficace... on pourrait se les approprier ?

if exist %systemroot%\system32\grouppolicy  rd /s /q %systemroot%\system32\grouppolicy && echo GPO supprimees

pushd %systemdrive%\netinst
time /T> debutwin.txt

date /T> logs\domscripts.txt
echo lancement de la mise au domaine se3 :>>logs\domscripts.txt
call action.bat
type action.bat >>logs\domscripts.txt

if "%1%"=="quitte" set ACTION=quitte

net user administrateur /active:yes

net user administrateur wawa>NUL
if errorlevel 1 (
    net user administrateur wawa /add>NUL 
    net localgroup Administrateurs administrateur /add 
)
net accounts /maxpwage:unlimited


if "%ACTION%"=="manuel" goto manuel
if "%ACTION%"=="clone" goto clone
if "%ACTION%"=="renomme" goto renomme
if "%ACTION%"=="rejoint" goto rejoint
if "%ACTION%"=="quitte" goto cpau
:clone
echo Mode clone donc suppression du unattend.csv de netinst
del /f /q unattend.csv
:manuel
echo set ACTION=clone> action.bat
set NAME=clone
echo 
if not exist "%systemdrive%\netinst\action.bat" echo Pas de action.bat
if exist "%systemdrive%\netinst\action.bat" echo Contenu de action.bat
if exist "%systemdrive%\netinst\action.bat" type action.bat
echo ========================== 
if "%DEBUG%"=="1" pause
goto cpau

:renomme
echo set ACTION=rejoint> action.bat
echo set NAME=%NAME%>> action.bat
if not exist "%systemdrive%\netinst\action.bat" echo Pas de action.bat
if exist "%systemdrive%\netinst\action.bat" echo Contenu de action.bat
if exist "%systemdrive%\netinst\action.bat" type action.bat
echo ==========================
if "%DEBUG%"=="1" pause

:cpau
:: on quitte le domaine
echo on quitte le domaine
time /T >> logs\domscripts.txt
echo sortie du domaine de %computername%>> logs\domscripts.txt
:: necessaire pour cpau
net start "connexion secondaire" 2>NUL
:: nom du service sous seven :
net start "Ouverture de session secondaire" 2>NUL
start /wait %systemdrive%\netinst\CPAU.exe -wait -dec -lwp -cwd %SystemDrive%\ -file %SystemDrive%\netinst\shutdown.job
if not exist "%systemdrive%\netinst\logs\domscripts.txt" echo Pas de domscripts.txt
if exist "%systemdrive%\netinst\logs\domscripts.txt" echo Contenu de domscripts.txt
if exist "%systemdrive%\netinst\logs\domscripts.txt" type logs\domscripts.txt
echo ========================== 
if "%DEBUG%"=="1" pause
if "%ACTION%"=="quitte" goto suite

:rejoint
:: on la renomme
time /T >> logs\domscripts.txt
echo renommage de %computername% en %NAME% >> logs\domscripts.txt

reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v "ForceGuest" /t REG_DWORD /d "0" /F 2>NUL 
REG.exe ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" /v ComputerName /t REG_SZ /d "%NAME%" /F
REG.exe ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "NV Hostname" /t REG_SZ /d "%NAME%" /F
REG.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d "0" /F
:: pour seven
if errorlevel 1 (
    echo passage en administrateur pour seven>> logs\domscripts.txt
    start /wait %Systemdrive%\Netinst\CPAU.exe -u administrateur -p wawa -ex %SystemDrive%\Netinst\shutdown.cmd -wait -lwp -cwd %SystemDrive%\Netinst
    exit
)    
:: on prepare le lancement du script de remise au domaine au reboot

reg.exe add "HKey_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SE3install" /d "%SystemDrive%\netinst\integSE3.cmd" /F >NUL

:: reboot en tant qu'administrateur, mdp wawa :)

echo Au prochain reboot : on demarrera sur ce poste %name%, pas sur le SE3_DOMAIN...
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" /d "%NAME%" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultUserName" /d "administrateur" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultPassword" /d "wawa" /F >NUL
reg.exe add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoAdminLogon" /d "1" /F >NUL

echo Les cles de registre sont positionnees
echo ==========================
if "%DEBUG%"=="1" pause


:suite
echo Nettoyage des fichiers wpkg...

if exist "%SystemRoot%\wpkg.txt" del /F /Q "%SystemRoot%\wpkg.txt"
if exist "%SystemRoot%\wpkg.log" del /F /Q "%SystemRoot%\wpkg.log"
if exist "%SystemRoot%\wpkg-client.vbs" del /F /Q "%SystemRoot%\wpkg-client.vbs"
if exist "%SystemRoot%\system32\wpkg.xml" del /F /Q "%SystemRoot%\system32\wpkg.xml"

if "%ACTION%"=="clone" (
    echo poste emetteur en attente de clonage
    echo on attend que le serveur soit pret pour rebooter...
    time /T>finwin.txt
    call se3rapport.cmd pre y
) else (
    echo Redemarrage immediat
    echo shutdown OK>> logs\domscripts.txt
)    
echo On va lancer le shutdown avec ACTION=%ACTION%
echo ==========================
if "%DEBUG%"=="1" pause

if "%ACTION%"=="manuel" (
	%SystemRoot%\system32\shutdown.exe -s -t 3  -c "%ACTION% : le poste est pret pour le clonage manuel"
) else (
	%SystemRoot%\system32\shutdown.exe -r -t 3  -c "%ACTION% : le poste est pret"
)

