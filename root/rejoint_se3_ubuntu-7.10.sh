#!/bin/bash
#
##### Script permettant de rejoindre un client edubuntu au serveur SE3#####
#
# Auteur : Mickaël POIRAULT Mickael.Poirault@ac-poitiers.fr
#
## $Id$ ##

# Tests effectués avec une Edubuntu 7.10

SE3_SERVER="###SE3_SERVER###"
SE3_IP="###SE3_IP###"
BASE_DN="###BASE_DN###"
LDAP_SERVER="###LDAP_SERVER###"
NTPSERVERS="###NTPSERVERS###"
NTPOPTIONS="###NTPOPTIONS###"
TLS="###TLS###"

# valeurs systèmes
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
	echo "Permet de faire rejoindre un client edubuntu au serveur SE3."
	echo "Les tests ont été effectués avec une ubuntu 7.10"
	echo "Ce script est à lancer sur le client en root."
	echo "Les données du serveur SE3 sont :"
	echo "  $SE3_SERVER : nom du serveur Se3"
	echo "  $SE3_IP : ip du serveur Se3"
	echo "  $BASE_DN : base dn de l'annuaire"
	echo "  $LDAP_SERVER : addresse du serveur ldap"
	echo "  $NTPSERVERS : serveur de temps pour ntpdate"
	echo "  $NTPOPTIONS : options pour ntpdate"
	echo "Usage : ./$0"
	echo "Ce script est distribué selon les termes de la licence GPL"
	echo "--help cette aide"

	echo -e "$COLTXT"
	exit
fi

# comment rendre le script "cretin-résistant", par Christian Westphal
TEST_CLIENT=`ifconfig | grep ":$SE3_IP "`
if [ ! -z "$TEST_CLIENT" ]; then
	echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur."
	exit
fi


[ -e /var/www/se3 ] && echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur." && exit 1
# Récupération de la date et de l'heure pour la sauvegarde des fichiers

DATE=$(date +%D_%Hh%M | sed -e "s§/§_§g")

# Modification du fichier /etc/apt/sources.list
echo -e "$COLPARTIE"
echo "Modification du /etc/apt/sources.list"
echo -e "$COLCMD\c"
cp /etc/apt/sources.list /etc/apt/sources_sauve_$DATE.list
perl -pi -e "s&deb cdrom&# deb cdrom&" /etc/apt/sources.list

# Mise à jour de la machine
echo -e "$COLPARTIE"
echo "Mise à jour de la machine..."
echo -e "$COLCMD\c"

# Résolution du probleme de lock
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

# Installation des paquets nécessaires
echo -e "$COLPARTIE"
echo "Installation des paquets nécessaires:"
echo -e "$COLTXT"
echo "Ne rien remplir, les fichiers sont configurés/modifiés automatiquement après..."
echo -e "$COLCMD\c"
apt-get install --assume-yes libnss-ldap  libpam-ldap lsof libpam-mount smbfs samba-common ntpdate ocsinventory-agent

# Suppression de gnome-mount pour que le montage des clés usb soit possible
apt-get remove --assume-yes gnome-mount
apt-get install --assume-yes pmount

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

TLS_OK="$TLS"
if [ "$TLS_OK" = "1" ]; then
	REPONSE=""
	while [ "$REPONSE" != "o" -a "$REPONSE" != "n" ]
	do
		echo -e "$COLTXT"
		echo "Souhaitez vous activer TLS sur LDAP?"
		echo "(non testé avec la distrib Edubuntu...)"
		echo -e "Votre serveur semble le permettre [${COLCHOIX}o/n${COLTXT}]"
		read REPONSE
	done
fi

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

if [ "$REPONSE" = "o" -o "$REPONSE" = "O" ]
then
echo "
ssl start_tls
tls_checkpeer no" >> /etc/ldap.conf
fi

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

TROUVE_DOSSIER(){
	retour=""
	for dossier in /bin /sbin /usr/bin /usr/sbin
	do
		ls $dossier/$1 2> /dev/null 1>&2
		if [ "$?" = "0" ]; then
			retour=$dossier
		fi
	done

	echo "$retour"
}

chemin_lsof=$(TROUVE_DOSSIER lsof)
chemin_losetup=$(TROUVE_DOSSIER losetup)
chemin_mount=$(TROUVE_DOSSIER mount)
chemin_umount=$(TROUVE_DOSSIER umount)
chemin_smbmount=$(TROUVE_DOSSIER smbmount)
chemin_smbumount=$(TROUVE_DOSSIER smbumount)
chemin_fsck=$(TROUVE_DOSSIER fsck)
chemin_mount_cifs=$(TROUVE_DOSSIER mount.cifs)

# Configuration du fichier /etc/security/pam_mount.conf
echo -e "$COLTXT"
echo "Configuration du fichier /etc/security/pam_mount.conf"
echo -e "$COLCMD\c"
cp /etc/security/pam_mount.conf /etc/security/pam_mount_sauve_$DATE.conf
echo "
# /etc/security/pam_mount.conf
# Configuration pour SambaEdu3

debug 0
mkmountpoint 1
fsckloop /dev/loop7
options_allow   nosuid,nodev,loop,encryption,fsck
options_require nosuid,nodev

lsof $chemin_lsof/lsof %(MNTPT)
fsck $chemin_fsck/fsck -p %(FSCKTARGET)
losetup $chemin_losetup/losetup -p0 \"%(before=\\\"-e\\\" CIPHER)\" \"%(before=\\\"-k\\\" KEYBITS)\" %(FSCKLOOP) %(VOLUME)
unlosetup $chemin_losetup/losetup -d %(FSCKLOOP)
#cifsmount /bin/mount -t cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
cifsmount $chemin_mount_cifs/mount.cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
#smbmount /usr/bin/smbmount   //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
#ncpmount /usr/bin/ncpmount   %(SERVER)/%(USER) %(MNTPT) -o \"pass-fd=0,volume=%(VOLUME)%(before=\\\",\\\" OPTIONS)\"
#smbumount /usr/bin/smbumount %(MNTPT)
#ncpumount /usr/bin/ncpumount %(MNTPT)
# Linux supports lazy unmounting (-l).  May be dangerous for encrypted volumes.
# May also break loopback mounts because loopback devices are not freed.
# Need to unmount mount point not volume to support SMB mounts, etc.
umount /usr/sbin/umountH.sh %(MNTPT)
# On OpenBSD try \"/usr/local/bin/mount_ehd\" (included in pam_mount package).
#lclmount /bin/mount -p0 -t %(FSTYPE) %(VOLUME) %(MNTPT) \"%(before=\\\"-o\\\" OPTIONS)\"
#cryptmount /bin/mount -t crypt \"%(before=\\\"-o\\\" OPTIONS)\" %(VOLUME) %(MNTPT)
#nfsmount /bin/mount %(SERVER):%(VOLUME) %(MNTPT) \"%(before=\\\"-o\\\" OPTIONS)\"
# For BSD: mntagain mount_null %(PREVMNTPT) %(MNTPT)
# For Solaris: mntagain mount -F lofs %(PREVMNTPT) %(MNTPT)
#mntcheck /bin/mount # For BSD's (don't have /etc/mtab)
#pmvarrun /usr/sbin/pmvarrun -u %(USER) -d -o %(OPERATION)

#volume * cifs $SE3_SERVER netlogon /home/netlogon mapchars,serverino,nobrl,iocharset=iso8859-15 - -
volume * cifs $SE3_SERVER & /home/& uid=&,gid=root,mapchars,serverino,nobrl,iocharset=iso8859-15 - -
volume * cifs $SE3_SERVER Classes /home/&/Desktop/Classes uid=&,gid=root,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - -
volume * cifs $SE3_SERVER Progs /home/&/Progs uid=&,gid=root,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - -
volume * cifs $SE3_SERVER Docs /home/&/Desktop/Partages uid=&,gid=root,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - - " > /etc/security/pam_mount.conf

# Création du script de démontage des lecteurs réseaux : umountH.sh
echo -e "$COLTXT"
echo "Création du script de démontage des lecteurs réseaux : umountH.sh"
echo -e "$COLCMD\c"
touch /usr/sbin/umountH.sh
chmod +x /usr/sbin/umountH.sh
echo "
#!/bin/bash
#
##### Script permettant de démonter correctement le /home/user#####
#
# Auteur : Mickaël POIRAULT Mickael.Poirault@ac-poitiers.fr
#


if [ \"\$1\" == \"--help\" -o \"\$1\" == \"-h\" ]
then
        echo \"Permet de démonter correctement le /home/user\"
        echo \"Ce script est lancé automatiquement par pam_mount\"
        echo \"Usage : /usr/sbin/umountH.sh /home/user\"
	echo \"Ce script est distribué selon les termes de la licence GPL\"
        echo \"--help cette aide\"

        exit
fi

killall trackerd 2>/dev/null
killall bluetooth-applet 2>/dev/null

# Détermination du répertoire à démonter
homeUSER=\$1

# Attendre la fin des processus qui utilisent le répertoire à démonter
until [ ``\`$chemin_lsof/lsof \$homeUSER | wc -l\``` = \"0\" ]
        do
                sleep 1
done

# Démontage du repertoire
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

# conf ocs-inventory
perl -pi -e "s&<OCSFSERVER>.*</OCSFSERVER>&<OCSFSERVER>$SE3_IP:909</OCSFSERVER>&" /etc/ocsinventory-client/ocsinv.conf

# On remonte l'inventaire
/usr/bin/ocsinventory-client.pl
# On reload crond
/etc/init.d/cron reload

# Fin de la configuration
echo -e "$COLTITRE"
echo "Fin de l'installation."
echo -e "$COLINFO"
echo "ATTENTION : Seul les comptes ayant un shell peuvent se connecter"
echo ""
echo "Vous devez configurer les locale pour être compatible avec Se3"
echo "pour cela faire un apt-get install locales et lire la doc sur www.sambaedu.org"
echo ""
echo "Les clients LTSP du serveur Edubuntu peuvent aussi se connecter"
echo "sur le domaine SE3"
echo "(voir documentation sur la configuration DHCP si les SE3 fait déjà DHCP)."
echo -e "$COLTXT"


DEBIAN_PRIORITY="high"
DEBIAN_FRONTEND="dialog"
export  DEBIAN_PRIORITY
export  DEBIAN_FRONTEND

exit 0
