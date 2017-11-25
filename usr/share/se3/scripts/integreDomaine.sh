#!/bin/bash


## $Id$ ##
#
# /usr/share/se3/scripts/integreDomaine.sh $action $name $ip $mac [$adminname $adminpasswd]
# ce script permet de sortir un poste du domaine si il y est deja, et de l'y remettre
# sous un autre nom.
# l'enregistrement ldap cn=machine est également mis à jour.  
#
# On utilise le mecanisme des GPO locales : copie d'un script shutdown.cmd par admin$,
# qui sort le poste du domaine et configure le demarrage au boot suivant, 
# copie dans %systemdrive%\netinst de tout ce qu'il faut pour la mise au domaine au reboot,
# puis on initie un reboot par rpc.
# 
# si cela foire, on lance rejointSE3 depuis le poste.
# usage :
# integreDomaine.sh  rejoint  $nom $ip $mac [$adminame] [$passadmin]  : met au domaine
# integredomaine.sh  renomme  $nom $ip $anciennom [$adminame] [$passadmin] : renomme
# integredomaine.sh   clone    $nom $ip $mac [$adminame] [$passadmin] : prepare le clonage
# integredomaine.sh   ldap    $nom $ip $mac    : met uniquement a jour le ldap
#
#  le script rejointSE3 
# recupere l'action dans \\se3\netlogon\machine\$ip\  
# 
if [ -f  /home/netlogon/$3.lck ]; then 
    exit 0
fi
>/home/netlogon/$3.lck


function mkgpopasswd 
{
[ -f /home/netlogon/machine/$1 ] && rm -f /home/netlogon/machine/$1
[ ! -d /home/netlogon/machine/$1 ] && mkdir -p /home/netlogon/machine/$1
(
echo username=$1\\$adminname
echo password=$passadmin
)>$logondir/gpoPASSWD
chmod  600 $logondir/gpoPASSWD
chown adminse3 $logondir/gpoPASSWD
}

function uploadGPO # argument : $remotename $localname $remotedom 
{
mkgpopasswd $3
smbclient  //$ip/ADMIN$ -A /home/netlogon/machine/"$2"/gpoPASSWD << EOF
	mkdir \System32\GroupPolicy
	mkdir \System32\GroupPolicy\Machine
	mkdir \System32\GroupPolicy\Machine\Scripts
	mkdir \System32\GroupPolicy\Machine\Scripts\Startup
	mkdir \System32\GroupPolicy\Machine\Scripts\Shutdown
	put $logondir/shutdown.cmd \System32\GroupPolicy\Machine\Scripts\Shutdown\shutdown.cmd
	put $domscripts/startup.cmd \System32\GroupPolicy\Machine\Scripts\Startup\startup.cmd
	put $logondir/registry.pol \System32\GroupPolicy\Machine\registry.pol
	put $logondir/gpt.ini \System32\GroupPolicy\gpt.ini
	put /home/netlogon/scriptsC.ini \System32\GroupPolicy\Machine\Scripts\scripts.ini
    prompt OFF
#	rmdir \System32\GroupPolicy\User
	rm \tasks\wpkg.job  
EOF
	return $?
}
function setADM
{
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy/gpt.ini" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy/Machine" -C "$1\\administrateur" || return $?
#	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy/Machine/registry.pol" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/Machine/Scripts" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/Machine/Scripts/scripts.ini" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/Machine/Scripts/Startup" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/Machine/Scripts/Startup/startup.cmd" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/Machine/Scripts/Shutdown" -C "$1\\administrateur" || return $?
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/Machine/Scripts/Shutdown/shutdown.cmd" -C "$1\\administrateur" || return $?
	
}

function uploadDom # argument : $remotename $localname $remotedom 
{
mkgpopasswd $3
smbclient  //$ip/C$ -A /home/netlogon/machine/"$2"/gpoPASSWD << EOF
	mkdir Netinst
	mkdir Netinst\logs
	put /home/netlogon/machine/$2/action.bat Netinst\action.bat
        put /home/netlogon/CPAU.exe Netinst\CPAU.exe
        cd Netinst
	lcd $domscripts
        prompt OFF
        mput -y *
EOF
#if [ "$adminname" == "adminse3" ]; then
#    smbclient  //"$1"/C$ -A /home/netlogon/machine/"$2"/gpoPASSWD << EOF
#        prompt OFF
#        rmdir "\Documents and Settings\Administrateur" 
#EOF
#fi
return $?
}



function setACL
{
#	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy/Machine/registry.pol" -a "ACL:adminse3:ALLOWED/0/FULL,ACL:SYSTEM:ALLOWED/0/FULL"
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/gpt.ini" -a "ACL:adminse3:ALLOWED/0/FULL,ACL:SYSTEM:ALLOWED/0/FULL"
	smbcacls //$ip/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD  "/System32/Grouppolicy/Machine/Scripts/scripts.ini" -a "ACL:adminse3:ALLOWED/0/FULL,ACL:SYSTEM:ALLOWED/0/FULL"
	smbcacls //$ip/ADMIN$  -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy/Machine/Scripts/Startup/startup.cmd" -a "ACL:adminse3:ALLOWED/0/FULL,ACL:SYSTEM:ALLOWED/0/FULL"
	smbcacls //$ip/ADMIN$  -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy/Machine/Scripts/Shutdown/shutdown.cmd" -a "ACL:adminse3:ALLOWED/0/FULL,ACL:SYSTEM:ALLOWED/0/FULL"
	smbcacls //$ip/ADMIN$  -A /home/netlogon/machine/$2/gpoPASSWD "/System32/Grouppolicy/gpt.ini" -a "ACL:adminse3:ALLOWED/0/FULL"
}

function tryuploadgpo # remotename remotedom
{ 
                
                uploadGPO $1 $ip $2  >/dev/null  2>&1 
                if [ "$?" == "0" ]
                then
                    setADM $1 $ip
                    setACL $1 $ip
                    uploadDom $1 $ip $2 >/dev/null  2>&1
       	            cp $logondir/action.bat /home/netlogon/machine/$oldname
    	            rm -rf $logondir

      	            if [ "action" == "clone" ]; then
    	                echo "clonage : la machine est prete<br>"
    	            else
    	                # on fait l'enregistrement ldap de la machine et on efface l'ancien si besoin
                        /usr/share/se3/shares/shares.avail/connexion.sh adminse3 $name $ip $mac
                        # /usr/share/se3/sbin/update-csv.sh
                    fi
                    /usr/bin/net rpc shutdown -t 30 -r -C "$action  : Le poste $oldname ($ip) va etre renomme $name avec $2/$adminname%XXXXXXX " -I $ip -U "$2/$adminname%$passadmin" 
    	            return 0 
                else
                    echo "integration a distance : connexion a $1 impossible avec $2/$adminname...<br>" 
                    return 1
                fi
}

# initialisation des variables
. /etc/se3/config_m.cache.sh

action="$1"
name=$(echo "$2" | tr 'A-Z' 'a-z')
ip="$3"

if [ -z "$5" ]; then
    adminname=adminse3
else
    adminname="$5"
fi
if [ -z "$6" ]; then 
    passadmin=$xppass
else
    passadmin="$6"
fi
# hack transitoire pour tester le nouveau systeme#
###################################################
mkgpopasswd $3
ret=$(echo quit|smbclient //"$3"/ADMIN$ -A /home/netlogon/machine/$2/gpoPASSWD 2>&1)
echo $ret
build=$(echo $ret | sed 's/\(^.*OS=\[Windows [0-9]\+ [a-zA-Z]\+ \([0-9]\+\).*\].*$\)/\2/g') 
if [ "$build" -ge "7601" ]; then
        if [ -f /usr/share/se3/scripts/sysprep.sh ]; then
                /usr/share/se3/scripts/sysprep.sh $*
        exit $?
fi
###################################################

if [ "$action" == "ldap" ]; then
    # on enregistre la machine dans la base ldap
    /usr/share/se3/shares/shares.avail/connexion.sh adminse3 $name $ip $4
#    /usr/share/se3/sbin/update-csv.sh
    [ -f /home/netlogon/machine/$name/action.bat ] && rm -f /home/netlogon/machine/$name/action.bat
else    
    if [ "$action" == "rejoint" ]; then
        oldname=$name
        mac="$4"
    else
        oldname=$(echo "$4" | tr 'A-Z' 'a-z')
    fi

    # on repere la machine par son iP et on copie les GPO de son ancien nom si elles existent
    domscripts=/home/netlogon/domscripts
    logondir="/home/netlogon/machine/$ip"
    [ -f "$logondir" ] && rm -f $logondir
    if [ ! -d "$logondir" ]; then
        mkdir -p $logondir
    fi
	rm -f $logondir/*
    /usr/share/se3/logonpy/logon.py adminse3 $ip XP 
    [ -f /home/netlogon/machine/$oldname ] && rm -f /home/netlogon/machine/$oldname
    if [ -d "/home/netlogon/machine/$oldname" ]; then 
	    cp "/home/netlogon/machine/$oldname/*" $logondir
	fi    
    echo -e "set ACTION=$action\r
set NAME=$name\r
">$logondir/action.bat
    sed -e "s/set ADMIN=.*$/set ADMIN=$adminname\r/;s/set PASSWD=.*$/set PASSWD=$passadmin\r/" $domscripts/shutdowngpo.cmd >$logondir/shutdown.cmd
	if [ ! -f "$logondir/gpt.ini" ]
	then
		cp -f /home/netlogon/gpt.ini $logondir/gpt.ini
	fi
	GPO_VERS="$(grep Version $logondir/gpt.ini|cut -d '=' -f2|sed -e 's/\r//g')"
	if [ -z "$GPO_VERS" ]; then 
		cp -f /home/netlogon/gpt.ini $logondir/gpt.ini
		GPO_VERS=268439552
	else	
		(( GPO_VERS+=268439552 ))
	fi
	sed -i "s/Version=.*/Version=$GPO_VERS\r/g" $logondir/gpt.ini
	if [ "$passadmin" != "$xppass" ]; then
        # Création du job cryptant le md administrateur local
        export HOME=/root
        ############################
        WINECMD="env WINEDEBUG=-all wine"
        JOB=$logondir/localpw.job
        TASK="net user administrateur $2"
        $WINECMD /home/netlogon/CPAU.exe -u administrateur -p wawa -wait -enc -file $JOB -lwp -c -ex "$TASK" > /dev/null
    fi    

    chmod -R 755 $logondir
    chown -R adminse3 $logondir
    
    # Try to upload GPO
    # Sometime, Windows XP isn't ready to accept connexions on C$ (just after boot)
    # on essaie toutes les combinaisons ip/netbiosname.... 
    /usr/share/se3/sbin/tcpcheck 20 $ip:445 >/dev/null
    tryuploadgpo $oldname $oldname
    if [ "$?" == "1" ]; then  
        tryuploadgpo $ip $oldname
        if [ "$?" == "1" ]; then  
            tryuploadgpo $name $oldname
            if [ "$?" == "1" ]; then  
                tryuploadgpo $name $name          
                if [ "$?" == "1" ]; then  
                    echo "la mise au domaine ne peut pas se faire a distance. Vous
devez la lancer depuis le poste.<br> Pour cela il faut lancer le script 
\\\\$netbios_name\netlogon\domscripts\rejointSE3.cmd<br>" 1>&2
                fi
            fi
        fi
    fi
fi
rm -f /home/netlogon/$ip.lck

