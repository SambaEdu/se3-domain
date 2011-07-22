:: script lance en adminse3
:: il permet d'activer le compte adminse3 et de creer son profil, car sinon on a des surprises ensuite....
@echo off
pushd %SystemDrive%\netinst
time /T >> logs\domscripts.txt
echo etapefinale : finition de l'installation >> logs\domscripts.txt
call %systemdrive%\netinst\se3ip.bat
netsh firewall set portopening protocol=UDP port=137 name=se3_137 mode=ENABLE scope=CUSTOM addresses=%se3ip%/255.255.255.255
netsh firewall set portopening protocol=TCP port=139 name=se3_139 mode=ENABLE scope=CUSTOM addresses=%se3ip%/255.255.255.255
netsh firewall set portopening protocol=UDP port=138 name=se3_138 mode=ENABLE scope=CUSTOM addresses=%se3ip%/255.255.255.255
netsh firewall set portopening protocol=TCP port=445 name=se3_445 mode=ENABLE scope=CUSTOM addresses=%se3ip%/255.255.255.255
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v "AutoShareWks" /f 2>NUL
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v "ForceGuest" /t "REG_DWORD" /d "0" /f 2>NUL 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache" /v "Formatdatabase" /t "REG_DWORD" /d "1" /F 2>NUL
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache" /v "Enabled" /t "REG_DWORD" /d "0" /F 2>NUL

echo preparation des GPO

:: recherche du numero de version gpo et on l'incremente si il existe.
for /f "tokens=3 delims= " %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\GPO-List\0" /v Version ^| findstr REG_DWORD ') do @set /a VERSION=~%%c+65537
if "%VERSION%" == "" set VERSION=65537
:: creation des GPO minimales
mkdir %SYSTEMROOT%\System32\GroupPolicy
mkdir %SYSTEMROOT%\System32\GroupPolicy\Machine
mkdir %SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts
mkdir %SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts\Startup
mkdir %SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts\Shutdown

echo [general]>%SYSTEMROOT%\System32\GroupPolicy\gpt.ini
echo Version=%VERSION%>>%SYSTEMROOT%\System32\GroupPolicy\gpt.ini
echo gPCUserExtensionNames=[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{0F6B957E-509E-11D1-A7CC-0000F87571E3}][{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}]>>%SYSTEMROOT%\System32\GroupPolicy\gpt.ini
echo gPCMachineExtensionNames=[{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{0F6B957D-509E-11D1-A7CC-0000F87571E3}][{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B6664F-4972-11D1-A7CA-0000F87571E3}]>>%SYSTEMROOT%\System32\GroupPolicy\gpt.ini

copy %SYSTEMDRIVE%\netinst\scriptsC.ini %SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts\scripts.ini

echo rem script de demarrage se3>%SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts\Startup\Startup.cmd
echo echo ok^>^>%SystemDrive%\netinst\logs\GPO.txt>%SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts\Startup\Startup.cmd
echo rem script de demarrage se3>%SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts\Shutdown\Shutdown.cmd
echo del /F /Q %SystemDrive%\netinst\*>>%SYSTEMROOT%\System32\GroupPolicy\Machine\Scripts\Shutdown\Shutdown.cmd
gpupdate /force

echo lancement du job se3 en adminse3
start /wait %systemdrive%\netinst\CPAU.exe -wait -dec -lwp -cwd %systemdrive%\netinst -file %SystemDrive%\netinst\se3.job
echo nettoyage du script se3.cmd
del /F /Q %SystemDrive%\netinst\se3.cmd
if exist "%systemDrive%\Documents and settings\administrateur_savse3" rd /S /Q "%systemDrive%\Documents and settings\administrateur_savse3"
if exist "%systemDrive%\Documents and settings\administrateur" move "%systemDrive%\Documents and settings\administrateur" "%systemDrive%\Documents and settings\administrateur_savse3" && echo profil administrateur renomme

echo le poste est pret : fin de la mise au domaine>> logs\domscripts.txt
%SystemRoot%\system32\shutdown.exe -r -t 5 -c "Windows est pret pour se3 : les programmes vont s'installer au prochain reboot"

