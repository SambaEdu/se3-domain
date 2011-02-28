:: rapport pour les domscripts
:: arguments : 
:: se3rapport.cmd pre|post y|message_erreur

@echo off

set ACTION=%1%
set BILAN=%2%

echo ############### Remontee des rapports pour les actions se3-domain ##################
:: Récupération des heures laissées sur le disque à divers moments de l'install
if not exist %SystemDrive%\netinst\debutwin.txt Goto erreurdebutwin
for /F "tokens=1 delims= " %%o in (%SystemDrive%\netinst\debutwin.txt) do (set DEBUTWIN=%%o)
echo Heure de debut d'installation windows : %DEBUTWIN%
del /F /Q %SystemDrive%\netinst\debutwin.txt
Goto findebutwin

:erreurdebutwin
echo Heure de debut d'install absente...
set DEBUTWIN=ABS

:findebutwin

if not exist %SystemDrive%\netinst\finwin.txt Goto erreurfinwin
    for /F "tokens=1 delims= " %%o in (%SystemDrive%\netinst\finwin.txt) do (set FINWIN=%%o)
    echo Heure de fin d'installation windows : %FINWIN%
    del /F /Q %SystemDrive%\netinst\finwin.txt
    Goto finfinwin

:erreurfinwin
    echo Heure de fin d'install windows absente...
	time /T > %SystemDrive%\netinst\finwin.txt
	for /F "tokens=1 delims= " %%o in (%SystemDrive%\netinst\finwin.txt) do (set FINWIN=%%o)
	del /F /Q %SystemDrive%\netinst\finwin.txt

:finfinwin

echo Heure de fin d'installation se3 et programmes wpkg generee : %FINWIN%

for /f "delims==- tokens=2-7" %%a in ('nbtstat -a %computername% ^| find "Adresse MAC"')  do @set mac=%%a-%%b-%%c-%%d-%%e-%%f
:: saloperie de dos !
set MACADDR=%mac:~1%
echo Adresse MAC de la carte ayant servi a l'install  : %MACADDR%
if not exist %SystemDrive%\netinst\wget.exe goto notexistwget
	call %SystemDrive%\netinst\se3ip.bat > NUL
	echo Recuperation de l'adresse de l'interface SE3 : %urlse3%
	echo Remontee du rapport d'install sur le SE3...
	if "%BILAN%"=="y" goto bilanyes else goto bilano
	:bilanyes
		echo Succes total de l'installation transmis au SE3.
		%SystemDrive%\netinst\wget.exe --no-cache --no-proxy -O %SystemDrive%\netinst\logs\rapport.htm -t 1 %urlse3%/tftp/remontee_udpcast.php?num_op=1^&debut=%DEBUTWIN%^&fin=%FINWIN%^&succes=y^&mac=%MACADDR%^&umode=%ACTION%
	    goto finbilan
	:bilano
	    echo erreur : %BILAN%
		%SystemDrive%\netinst\wget.exe --no-cache --no-proxy -O %SystemDrive%\netinst\logs\rapport.htm -t 1 %urlse3%/tftp/remontee_udpcast.php?debut=%DEBUTWIN%^&finwin=%FINWIN%^&succes=%BILAN%^&mac=%MACADDR%^&umode=%ACTION%
	:finbilan
::	del /F /Q %SystemDrive%\netinst\logs\rapport.htm

    goto suitewget
:notexistwget
	echo Logiciel wget absent : verifier sa presence dans \\se3\netlogon\domscripts\.
	pause
:suitewget

echo ############# Fin de la remontee des rapports tftp #####################
echo.
