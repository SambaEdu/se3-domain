
#!/bin/bash
#$Id$
# reconfigure les jobs de mise au domaine se3

# recuperation de xppass, se3_domain, netbios_name, se3ip 
. /usr/share/se3/includes/config.inc.sh -cm
adminse3=adminse3

# (re-)génération du profile wpkg unattended : il permet l'installation des programmes destinés à "_Touslespostes"


# Création d'un job CPAU qui connait le mdp adminse3 , entre autres
unattendedSCRIPTS="/home/netlogon/domscripts"
############################
# Fix for wine when running from sudo
export HOME=/root
############################
JOB=se3.job
WINECMD="env WINEDEBUG=-all wine"
rm -f $unattendedSCRIPTS/$JOB
echo "Creation du job CPAU se3.job qui lancera se3.cmd destine a installer les composants nécessaires a SAMBAEDU3 et tous les programmes wpkg"
TASK="set NETBIOS_NAME=$netbios_name&set SE3_DOMAIN=$se3_domain&set XPPASS=$xppass&call c:\\netinst\\se3.cmd&net use * /delete /y"
echo "TASK se3 : $TASK" | sed -e "s/$xppass/XXXXXX/g"
cd /tmp
#wine /home/netlogon/CPAU.exe -u "$adminse3" -wait  -p "$xppass" -file $JOB -lwp  -ex "$TASK" -enc 
$WINECMD /home/netlogon/CPAU.exe -u adminse3 -wait  -p $xppass -file $JOB -lwop  -c -ex "$TASK" -enc > /dev/null
mv $JOB $unattendedSCRIPTS

# Création du job de jonction au domaine, de création du compte adminse3 administrateur local (sous lequel va s'ouvrir le se3.job)
# le job s'executera sous le compte administrateur avec mot de passe wawa: le seul intérêt de cette opération est de crypter le mdp de SAMBAEDU3\adminse3

JOB=netdom.job
rm -f $unattendedSCRIPTS/$JOB
echo "Creation du job CPAU netdom.job qui joindra le client au domaine $se3_domain"
#TASK="net user $adminse3 $xppass /add&net localgroup Administrateurs $adminse3 /add&call c:\\netinst\\se3netdom.cmd $se3_domain $adminse3 $xppass"
TASK="call c:\\netinst\\se3netdom.cmd $se3_domain $adminse3 $xppass"
echo "TASK : $TASK" | sed -e "s/$xppass/XXXXXX/g"
$WINECMD /home/netlogon/CPAU.exe -u administrateur -p wawa -wait -enc -file $JOB -lwp -c -ex "$TASK" > /dev/null
mv $JOB $unattendedSCRIPTS

# Création du job de sortie du domaine
# le job s'executera sous le compte administrateur local: le seul intérêt de cette opération est de crypter le mdp de SAMBAEDU3\adminse3

JOB=shutdown.job
rm -f $unattendedSCRIPTS/$JOB
echo "Creation du job CPAU shutdownjob.job qui sortira le client au domaine $se3_domain"
TASK="call c:\\netinst\\shutdownjob.cmd $se3_domain $adminse3 $xppass"
echo "TASK : $TASK" | sed -e "s/$xppass/XXXXXX/g"
$WINECMD /home/netlogon/CPAU.exe  -u administrateur -p wawa -enc  -wait -file $JOB -lwp -c -ex "$TASK" > /dev/null
mv $JOB $unattendedSCRIPTS


cd - >/dev/null 2>&1

echo -e "set SE3IP=$se3ip\r
set urlse3=$urlse3\r" > /home/netlogon/domscripts/se3ip.bat
# pour le post-clonage manuel
echo -e "[ParamSE3]\r
netbios_name=$netbios_name\r
se3ip=$se3ip\r
se3_domain=$se3_domain\r"  > /home/netlogon/domscripts/se3ip.ini

sed -i "s/set netbios_name=.*$/set netbios_name=$netbios_name\r/" /home/netlogon/domscripts/rejointSE3.cmd
sed -i "s/set se3ip=.*$/set se3ip=$se3ip\r/" /home/netlogon/domscripts/rejointSE3.cmd

chmod 666 /home/netlogon/domscripts/*
 if [ -L /var/se3/Progs/install/domscripts ]; then
 	rm -f /var/se3/Progs/install/domscripts
 fi
if [ -e /var/se3/Progs/install/installdll ]; then
	rm -rf /var/se3/Progs/install/installdll
# 	ln -s /home/netlogon/CPAU.exe /var/se3/Progs/install/installdll/CPAU.exe
# else
# 	mkdir -m 755 /var/se3/Progs/install/installdll
# 	ln -s /home/netlogon/CPAU.exe /var/se3/Progs/install/installdll/CPAU.exe
fi

if [ ! -e /var/se3/Progs/install/domscripts ]; then
	ln -s /home/netlogon/domscripts /var/se3/Progs/install/domscripts
fi