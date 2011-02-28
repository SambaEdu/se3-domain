#!/bin/bash
#
##### Script permettant de rejoindre un client ubuntu-6.06 au serveur SE3#####
#
# Auteur : Mickaël POIRAULT Mickael.Poirault@ac-versailles.fr
# Adaptation ubuntu 6.10 Philippe Chadefaux
#
## $Id$ ##

if [ "$1" == "--help" -o "$1" == "-h" ]
then
	echo "Permet de faire rejoindre un client ubuntu-6.06 au serveur SE3"
	echo "Ce script est à lancer sur le client en root"
	echo "Les données du serveur SE3 sont :"
	echo "###SE3_SERVER### : nom du serveur Se3"
	echo "###SE3_IP### : ip du serveur Se3"
	echo "###BASE_DN### : base dn de l'annuaire"
	echo "###LDAP_SERVER### : addresse du serveur ldap"
	echo "###NTPSERVERS### : serveur de temps pour ntpdate"
	echo "###NTPOPTIONS### : options pour ntpdate"
	echo "Usage : ./rejoint_se3_ubuntu-6.06.sh"
	echo "Ce script est distribué selon les termes de la licence GPL"
	echo "--help cette aide"

	exit
fi

# comment rendre le script "cretin-résistant", par Christian Westphal
TEST_CLIENT=`ifconfig | grep ":###SE3_IP### "`
if [ ! -z "$TEST_CLIENT" ]; then
	echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur."
	exit
fi

[ -e /var/www/se3 ] && echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur." && exit 1
# On commence par récupérer la date et l'heure pour la sauvegarde des fichiers

DATE=$(date +%D_%Hh%M | sed -e "s§/§_§g")

# On modifie le fichier /etc/apt/sources.list

cp /etc/apt/sources.list /etc/apt/sources_sauve_$DATE.list
perl -pi -e "s&deb cdrom&# deb cdrom&" /etc/apt/sources.list
perl -pi -e 's&^# deb http://(.*)universe$&deb http://$1 universe&' /etc/apt/sources.list
perl -pi -e 's&^# deb-src http://(.*)universe$&deb-src http://$1 universe&' /etc/apt/sources.list

# On met à jour la machine
echo "Mise à jour de la machine"

# probleme de lock
if [ -e "/var/lib/dpkg/lock" ]
then
	rm -f /var/lib/dpkg/lock
fi

apt-get update
apt-get dist-upgrade

# Installation des paquets nécessaires
echo "Installation des paquets nécessaires"
echo "Ne rien remplir, les fichiers sont configurés automatiquement après"
apt-get install --assume-yes libnss-ldap  libpam-ldap lsof libpam-mount smbfs samba-common ntpdate

# Configuration des fichiers

echo "Configuration"

cp /etc/hosts /etc/hosts_sauve_$DATE
OK_SE3=`cat /etc/hosts | grep ###SE3_SERVER###`
if [ "$OK_SE3" == "" ]
then
	echo "###SE3_IP###	###SE3_SERVER###" >> /etc/hosts
fi

TLS_OK="###TLS###"
if [ "$TLS_OK" = "1" ]
then
	echo "Souhaitez vous activer TLS sur LDAP"
	echo "Votre serveur semble le permettre [o/n]"
	read REPONSE
	while [ "$REPONSE" != "o" -a "$REPONSE" != "n" ]
	do
		echo "Souhaitez vous activer TLS sur LDAP"
		echo "Votre serveur semble le permettre [o/n]"
		read REPONSE
	done
fi

# Configuration du fichier /etc/pam_ldap.conf

cp /etc/pam_ldap.conf /etc/pam_ldap_sauve_$DATE.conf
echo "
# /etc/pam_ldap.conf
# Configuration pour Sambaedu3

host ###LDAP_SERVER###
base ###BASE_DN###
ldap_version 3
port 389
bind_policy soft
pam_password md5" > /etc/pam_ldap.conf

if [ "$REPONSE" = "o" -o "$REPONSE" = "O" ]
then
echo "
ssl start_tls
tls_checkpeer no" >> /etc/pam_ldap.conf
fi

# Configuration du fichier /etc/libnss-ldap.conf

cp /etc/libnss-ldap.conf /etc/libnss-ldap_sauve_$DATE.conf
echo "
# /etc/libnss-ldap.conf
# Configuration pour Sambaedu3
host ###LDAP_SERVER###
base ###BASE_DN###
ldap_version 3
port 389
bind_policy soft" > /etc/libnss-ldap.conf

if [ "$REPONSE" = "O" -o "$REPONSE" = "o" ]
then
echo "
ssl start_tls
tls_checkpeer no" >> /etc/libnss-ldap.conf
fi

# Configuration du fichier /etc/nsswitch.conf

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
session	optional	am_lastlog.so
session	optional	pam_motd.so
session	optional	pam_mail.so standard
@include common-password" > /etc/pam.d/login

# Configuration du fichier /etc/pam.d/common-auth

cp /etc/pam.d/common-auth /etc/pam.d/common-auth_sauve_$DATE
echo "
# /etc/pam.d/common-auth
# Configuration pour SambaEdu3

auth	optional	pam_group.so
auth	optional	pam_mount.so
auth	sufficient	pam_ldap.so    use_first_pass
auth	required	pam_unix.so    use_first_pass" > /etc/pam.d/common-auth

# Configuration du fichier /etc/pam.d/common-account

cp /etc/pam.d/common-account /etc/pam.d/common-account_sauve_$DATE
echo "
# /etc/pam.d/common-account
# Configuration pour SambaEdu3

account	sufficient	pam_ldap.so	use_first_pass
account	required	pam_unix.so	use_first_pass" > /etc/pam.d/common-account

# Configuration du fichier /etc/pam.d/common-session

cp /etc/pam.d/common-session /etc/pam.d/common-session_sauve_$DATE
echo "
# /etc/pam.d/common-session
# Configuration pour SambaEdu3

session	optional	pam_mount.so
session	required	pam_unix.so	use_first_pass" > /etc/pam.d/common-session

# Configuration du fichier /etc/pam.d/common-password

cp /etc/pam.d/common-password /etc/pam.d/common-password_sauve_$DATE
echo "
# /etc/pam.d/common-password
# Configuration pour SambaEdu3

password	required	pam_unix.so	nullok obscure min=8 md5" > /etc/pam.d/common-password

# Configuration du fichier /etc/pam.d/sudo

cp /etc/pam.d/sudo /etc/pam.d/sudo_sauve_$DATE
echo "
# /etc/pam.d/sudo
# Configuration pour SambaEdu3

auth	required	pam_unix.so	nullok_secure
@include common-account" > /etc/pam.d/sudo

# Configuration du fichier /etc/security/group.conf

cp /etc/security/group.conf /etc/security/group_sauve_$DATE.conf
echo "
# /etc/security/group.conf
# Configuration pour SambaEdu3

gdm;*;*;Al0000-2400;floppy,cdrom,audio,video,plugdev
kdm;*;*;Al0000-2400;floppy,cdrom,audio,video,plugdev" > /etc/security/group.conf

# Configuration du fichier /etc/security/pam_mount.conf

cp /etc/security/pam_mount.conf /etc/security/pam_mount_sauve_$DATE.conf

echo "
# /etc/security/pam_mount.conf
# Configuration pour SambaEdu3

debug 0
mkmountpoint 1
fsckloop /dev/loop7
options_allow   nosuid,nodev,loop,encryption,fsck
options_require nosuid,nodev

lsof /usr/sbin/lsof %(MNTPT)
fsck /sbin/fsck -p %(FSCKTARGET)
losetup /sbin/losetup -p0 \"%(before=\\\"-e\\\" CIPHER)\" \"%(before=\\\"-k\\\" KEYBITS)\" %(FSCKLOOP) %(VOLUME)
unlosetup /sbin/losetup -d %(FSCKLOOP)
#cifsmount /bin/mount -t cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
cifsmount /sbin/mount.cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
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

#volume * cifs ###SE3_SERVER### netlogon /home/netlogon mapchars,serverino,nobrl,iocharset=iso8859-15 - -
volume * cifs ###SE3_SERVER### & /home/& uid=&,gid=root,mapchars,serverino,nobrl,iocharset=iso8859-15 - -
volume * cifs ###SE3_SERVER### Classes /home/&/Desktop/Classes uid=&,gid=root,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - -
volume * cifs ###SE3_SERVER### Progs /home/&/Progs uid=&,gid=root,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - -
volume * cifs ###SE3_SERVER### Docs /home/&/Desktop/Partages uid=&,gid=root,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - - " > /etc/security/pam_mount.conf

# Création du script de démontage des lecteurs réseaux : umountH.sh

touch /usr/sbin/umountH.sh
chmod +x /usr/sbin/umountH.sh
echo "
#!/bin/bash
#
##### Script permettant de démonter correctement le /home/user#####
#
# Auteur : Mickaël POIRAULT Mickael.Poirault@ac-versailles.fr
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

# Détermination du répertoire à démonter
homeUSER=\$1

# Attendre la fin des processus qui utilisent le répertoire à démonter
until [ ``\`/usr/sbin/lsof \$homeUSER | wc -l\``` = \"0\" ]
        do
                sleep 1
done

# Démontage du repertoire
/bin/umount \$homeUSER" > /usr/sbin/umountH.sh

# Configuration du fichier /etc/default/ntpdate

cp /etc/default/ntpdate /etc/default/ntpdate_sauve_$DATE
echo "
# /etc/default/ntpdate
# Configuration pour SambaEdu3
# servers to check.   (Separate multiple servers with spaces.)
NTPSERVERS=\"###SE3_SERVER###\"

# additional options for ntpdate
###NTPOPTIONS###" > /etc/default/ntpdate

# Fin de la configuration
echo "Fin de l'installation."
echo "ATTENTION : Seul les comptes ayant un shell peuvent se connecter"
echo ""
echo "Vous devez configurer les locale pour être compatible avec Se3"
echo "pour cela faire un apt-get install locale et lire la doc sur www.sambaedu.org"
