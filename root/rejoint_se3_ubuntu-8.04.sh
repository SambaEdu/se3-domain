#!/bin/bash
#
##### Script permettant de rejoindre un client ubuntu au serveur SE3#####
#
# Auteur : Micka�l POIRAULT Mickael.Poirault@ac-poitiers.fr
#
## $Id$ ##

# Tests effectu�s avec une ubuntu 8.04

SE3_SERVER="###SE3_SERVER###"
SE3_IP="###SE3_IP###"
BASE_DN="###BASE_DN###"
LDAP_SERVER="###LDAP_SERVER###"
NTPSERVERS="###NTPSERVERS###"
NTPOPTIONS="###NTPOPTIONS###"
TLS="###TLS###"
IOCHARSET="###IOCHARSET###"

# valeurs syst�mes
DEBIAN_PRIORITY="critical"
DEBIAN_FRONTEND="noninteractive"
export DEBIAN_FRONTEND
export DEBIAN_PRIORITY


#Couleurs
COLTITRE="\033[1;35m"
COLPARTIE="\033[1;34m"

COLTXT="\033[0;37m"
COLCHOIX="\033[1;33m"
COLDEFAUT="\033[0;33m"
COLSAISIE="\033[1;32m"

COLCMD="\033[1;37m"

COLERREUR="\033[1;31m"
COLINFO="\033[0;36m"

if [ "$1" == "--help" -o "$1" == "-h" ]; then
	echo -e "$COLINFO"
	echo "Permet de faire rejoindre un client ubuntu au serveur SE3."
	echo "Les tests ont �t� effectu�s avec une ubuntu 8.04"
	echo "Ce script est � lancer sur le client en root."
	echo "Les donn�es du serveur SE3 sont :"
	echo "  $SE3_SERVER : nom du serveur Se3"
	echo "  $SE3_IP : ip du serveur Se3"
	echo "  $BASE_DN : base dn de l'annuaire"
	echo "  $LDAP_SERVER : addresse du serveur ldap"
	echo "  $NTPSERVERS : serveur de temps pour ntpdate"
	echo "  $NTPOPTIONS : options pour ntpdate"
	echo "  $TLS : options TLS pour le serveur ldap"
	echo "  $IOCHARSET : locale pour pam_mount.conf.xml"
	echo "Usage : ./$0"
	echo "Ce script est distribu� selon les termes de la licence GPL"
	echo "--help cette aide"

	echo -e "$COLTXT"
	exit
fi

# comment rendre le script "cretin-r�sistant", par Christian Westphal
TEST_CLIENT=`ifconfig | grep ":$SE3_IP "`
if [ ! -z "$TEST_CLIENT" ]; then
	echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur."
	exit
fi

[ -e /var/www/se3 ] && echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur." && exit 1


# R�cup�ration de la date et de l'heure pour la sauvegarde des fichiers

DATE=$(date +%D_%Hh%M | sed -e "s�/�_�g")

# Modification du fichier /etc/apt/sources.list
echo -e "$COLPARTIE"
echo "Modification du /etc/apt/sources.list"
echo -e "$COLCMD\c"
cp /etc/apt/sources.list /etc/apt/sources_sauve_$DATE.list
perl -pi -e "s&deb cdrom&# deb cdrom&" /etc/apt/sources.list

# Mise � jour de la machine
echo -e "$COLPARTIE"
echo "Mise � jour de la machine..."
echo -e "$COLCMD\c"

# R�solution du probleme de lock
if [ -e "/var/lib/dpkg/lock" ]; then
	rm -f /var/lib/dpkg/lock
fi

# On lance une maj
apt-get update
apt-get dist-upgrade

# On rechange le sources.list
perl -pi -e 's&^#.*deb http://(.*)universe$&deb http://$1 universe&' /etc/apt/sources.list
perl -pi -e 's&^# deb-src http://(.*)universe$&deb-src http://$1 universe&' /etc/apt/sources.list
perl -pi -e 's&^#.*deb http://(.*)restricted$&deb http://$1 restricted&' /etc/apt/sources.list

apt-get update

# Installation des paquets n�cessaires
echo -e "$COLPARTIE"
echo "Installation des paquets n�cessaires:"
echo -e "$COLTXT"
echo "Ne rien remplir, les fichiers sont configur�s/modifi�s automatiquement apr�s..."
echo -e "$COLCMD\c"
apt-get install --assume-yes libnss-ldap  libpam-ldap lsof libpam-mount smbfs samba-common ntpdate ssh ocsinventory-agent

# Configuration des fichiers
echo -e "$COLPARTIE"
echo "Configuration des fichiers..."

# Configuration du fichier /etc/hosts"
echo -e "$COLTXT"
echo "Configuration du fichier /etc/hosts"
echo -e "$COLCMD\c"
cp /etc/hosts /etc/hosts_sauve_$DATE
OK_SE3=`cat /etc/hosts | grep $SE3_SERVER`
if [ -z "$OK_SE3" ]; then
	echo "$SE3_IP	$SE3_SERVER" >> /etc/hosts
fi

#TLS_OK="$TLS"
#if [ "$TLS_OK" = "1" ]; then
#	REPONSE=""
#	while [ "$REPONSE" != "o" -a "$REPONSE" != "n" ]
#	do
#		echo -e "$COLTXT"
#		echo "Souhaitez vous activer TLS sur LDAP?"
#		echo -e "Votre serveur semble le permettre [${COLCHOIX}o/n${COLTXT}]"
#		read REPONSE
#	done
#fi

# Configuration du fichier /etc/ldap.conf
echo -e "$COLTXT"
echo "Configuration du fichier /etc/ldap.conf"
echo -e "$COLCMD\c"
cp /etc/ldap.conf /etc/ldap_sauve_$DATE.conf
echo "
# /etc/ldap.conf
# Configuration pour Sambaedu3

host $LDAP_SERVER
base $BASE_DN
ldap_version 3
port 389
bind_policy soft
pam_password md5" > /etc/ldap.conf

#if [ "$REPONSE" = "o" -o "$REPONSE" = "O" ]
#then
#echo "
#ssl start_tls
#tls_checkpeer yes" >> /etc/ldap.conf
#fi

# Configuration du fichier /etc/nsswitch.conf
echo -e "$COLTXT"
echo "Configuration du fichier /etc/nsswitch.conf"
echo -e "$COLCMD\c"
cp /etc/nsswitch.conf /etc/nsswitch_sauve_$DATE.conf
echo "
# /etc/nsswitch.conf
# Configuration pour SambaEdu3

passwd:         files ldap
group:          files ldap
shadow:         files ldap

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis" > /etc/nsswitch.conf

# Configuration du fichier /etc/pam.d/login
echo -e "$COLTXT"
echo "Configuration du fichier /etc/pam.d/login"
echo -e "$COLCMD\c"
cp /etc/pam.d/login /etc/pam.d/login_sauve_$DATE
echo "
# /etc/pam.d/login
# Configuration pour SambaEdu3

auth	requisite	pam_securetty.so
auth	requisite	pam_nologin.so
session	required	pam_env.so readenv=1
@include common-auth
@include common-account
@include common-session
session	required	pam_limits.so
#session	optional	am_lastlog.so
session	optional	pam_lastlog.so
session	optional	pam_motd.so
session	optional	pam_mail.so standard
@include common-password" > /etc/pam.d/login

# Configuration du fichier /etc/pam.d/common-auth
echo -e "$COLTXT"
echo "Configuration du fichier /etc/pam.d/common-auth"
echo -e "$COLCMD\c"
cp /etc/pam.d/common-auth /etc/pam.d/common-auth_sauve_$DATE
echo "
# /etc/pam.d/common-auth
# Configuration pour SambaEdu3

auth	optional	pam_group.so
auth	optional	pam_mount.so
auth	sufficient	pam_ldap.so    use_first_pass
auth	required	pam_unix.so    use_first_pass" > /etc/pam.d/common-auth

# Configuration du fichier /etc/pam.d/common-account
echo -e "$COLTXT"
echo "Configuration du fichier /etc/pam.d/common-account"
echo -e "$COLCMD\c"
cp /etc/pam.d/common-account /etc/pam.d/common-account_sauve_$DATE
echo "
# /etc/pam.d/common-account
# Configuration pour SambaEdu3

account	sufficient	pam_ldap.so	use_first_pass
account	required	pam_unix.so	use_first_pass" > /etc/pam.d/common-account

# Configuration du fichier /etc/pam.d/common-session
echo -e "$COLTXT"
echo "Configuration du fichier /etc/pam.d/common-session"
echo -e "$COLCMD\c"
cp /etc/pam.d/common-session /etc/pam.d/common-session_sauve_$DATE
echo "
# /etc/pam.d/common-session
# Configuration pour SambaEdu3

session	optional	pam_mount.so
session	required	pam_unix.so	use_first_pass" > /etc/pam.d/common-session

# Configuration du fichier /etc/pam.d/common-password
echo -e "$COLTXT"
echo "Configuration du fichier /etc/pam.d/common-password"
echo -e "$COLCMD\c"
cp /etc/pam.d/common-password /etc/pam.d/common-password_sauve_$DATE
echo "
# /etc/pam.d/common-password
# Configuration pour SambaEdu3

password	required	pam_unix.so	nullok obscure min=8 md5" > /etc/pam.d/common-password

# Configuration du fichier /etc/pam.d/sudo
echo -e "$COLTXT"
echo "Configuration du fichier /etc/pam.d/sudo"
echo -e "$COLCMD\c"
cp /etc/pam.d/sudo /etc/pam.d/sudo_sauve_$DATE
echo "
# /etc/pam.d/sudo
# Configuration pour SambaEdu3

auth	required	pam_unix.so	nullok_secure
@include common-account" > /etc/pam.d/sudo

# Configuration du fichier /etc/security/group.conf
echo -e "$COLTXT"
echo "Configuration du fichier /etc/security/group.conf"
echo -e "$COLCMD\c"
cp /etc/security/group.conf /etc/security/group_sauve_$DATE.conf
echo "
# /etc/security/group.conf
# Configuration pour SambaEdu3

gdm;*;*;Al0000-2400;floppy,cdrom,audio,video,plugdev
kdm;*;*;Al0000-2400;floppy,cdrom,audio,video,plugdev" > /etc/security/group.conf

# Configuration du fichier /etc/security/pam_mount.conf.xml
echo -e "$COLTXT"
echo "Configuration du fichier /etc/security/pam_mount.conf.xml"
echo -e "$COLCMD\c"
cp /etc/security/pam_mount.conf.xml /etc/security/pam_mount_sauve_$DATE.conf.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<!--
/etc/security/pam_mount.conf.xml
Configuration pour SambaEdu3
-->

<pam_mount>
<debug enable=\"0\" />
<mkmountpoint enable=\"1\" remove=\"true\" />
<fsckloop device=\"/dev/loop7\" />
<mntoptions allow=\"nosuid,nodev,loop,encryption,fsck\" />
<mntoptions require=\"nosuid,nodev\" />

<path>/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin</path>

<lsof>lsof %(MNTPT)</lsof>
<fsck>fsck -p %(FSCKTARGET)</fsck>
<losetup>losetup -p0 \"%(before=\\\"-e\\\" CIPHER)\" \"%(before=\\\"-k\\\" KEYBITS)\" %(FSCKLOOP) %(VOLUME)</losetup>
<unlosetup>losetup -d %(FSCKLOOP)</unlosetup>
<!--
<cifsmount>mount -t cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"</cifsmount>
-->
<cifsmount>mount.cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"</cifsmount>
<umount>umountH.sh %(MNTPT)</umount>

<!--
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"netlogon\" mountpoint=\"/home/netlogon\" user=\"*\" options=\"mapchars,serverino,nobrl,iocharset=$IOCHARSET\" />
-->
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"%(USER)\" mountpoint=\"/home/%(USER)\" user=\"*\" options=\"gid=root,mapchars,serverino,nobrl,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Classes\" mountpoint=\"/home/%(USER)/Classes\" user=\"*\" options=\"gid=root,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Docs\" mountpoint=\"/home/%(USER)/Partages\" user=\"*\" options=\"gid=root,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Progs\" mountpoint=\"/home/%(USER)/Progs\" user=\"*\" options=\"gid=root,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />

<msg-authpw>Mot de passe :</msg-authpw>
<msg-sessionpw>Mot de passe :</msg-sessionpw>

</pam_mount>" > /etc/security/pam_mount.conf.xml

# Cr�ation du script de d�montage des lecteurs r�seaux : umountH.sh
echo -e "$COLTXT"
echo "Cr�ation du script de d�montage des lecteurs r�seaux : umountH.sh"
echo -e "$COLCMD\c"
touch /usr/sbin/umountH.sh
chmod +x /usr/sbin/umountH.sh
echo "
#!/bin/bash
#
##### Script permettant de d�monter correctement le /home/user#####
#
# Auteur : Micka�l POIRAULT Mickael.Poirault@ac-poitiers.fr
#


if [ \"\$1\" == \"--help\" -o \"\$1\" == \"-h\" ]
then
        echo \"Permet de d�monter correctement le /home/user\"
        echo \"Ce script est lanc� automatiquement par pam_mount\"
        echo \"Usage : /usr/sbin/umountH.sh /home/user\"
	echo \"Ce script est distribu� selon les termes de la licence GPL\"
        echo \"--help cette aide\"

        exit
fi

killall trackerd 2>/dev/null
killall bluetooth-applet 2>/dev/null

# D�termination du r�pertoire � d�monter
homeUSER=\$1

# Attendre la fin des processus qui utilisent le r�pertoire � d�monter
until [ ``\`$chemin_lsof/lsof \$homeUSER | wc -l\``` = \"0\" ]
        do
                sleep 1
done

# D�montage du repertoire
/bin/umount \$homeUSER" > /usr/sbin/umountH.sh

# Configuration du fichier /etc/default/ntpdate
echo -e "$COLTXT"
echo "Configuration du fichier /etc/default/ntpdate"
echo -e "$COLCMD\c"
cp /etc/default/ntpdate /etc/default/ntpdate_sauve_$DATE
echo "
# /etc/default/ntpdate
# Configuration pour SambaEdu3
# servers to check.   (Separate multiple servers with spaces.)
#NTPSERVERS=\"$NTPSERVERS\"
NTPSERVERS=\"$SE3_SERVER\"

# additional options for ntpdate
$NTPOPTIONS" > /etc/default/ntpdate

# On recupere la cle publique du serveur
cd /root/.ssh
wget $SE3_IP:909/authorized_keys
chmod 400 /root/.ssh/authorized_keys
cd /

# Configuration de ocs-inventory
cp /etc/ocsinventory/ocsinventory-agent.cfg /etc/ocsinventory/ocsinventory-agent_sauve_$DATE.cfg
echo "
# /etc/ocsinventory/ocsinventory-agent.cfg
# Configuration pour SambaEdu3

server=$SE3_IP:909" > /etc/ocsinventory/ocsinventory-agent.cfg

# On remonte l'inventaire
/usr/bin/ocsinventory-agent &
# On reload crond
/etc/init.d/cron reload

# Fin de la configuration
echo -e "$COLTITRE"
echo "Fin de l'installation."
echo -e "$COLINFO"
echo "ATTENTION : Seul les comptes ayant un shell peuvent se connecter"
echo ""
echo "Vous devez configurer les locale pour �tre compatible avec Se3"
#echo "pour cela faire un apt-get install locales et lire la doc sur www.sambaedu.org"
echo ""
echo -e "$COLTXT"


DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog"
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND

exit 0
