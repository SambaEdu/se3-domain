#!/bin/bash
#
##### Script permettant de rejoindre un client sarge au serveur SE3#####
#
# Auteur : Mickaël POIRAULT Mickael.Poirault@ac-versailles.fr
#
## $Id$ ##

if [ "$1" == "--help" -o "$1" == "-h" ]
then
        echo "Permet de faire rejoindre un client sarge au serveur SE3"
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
# On commence par recuperer la date et l'heure pour la sauvegarde des fichiers

DATE=$(date +%D_%Hh%M | sed -e "s§/§_§g")

# On met a jour la machine

apt-get update
apt-get dist-upgrade

# Installation des paquets nécessaires

apt-get install --assume-yes libnss-ldap  libpam-ldap lsof libpam-mount smbfs samba-common ntpdate

# Configuration des fichiers

# Configuration du fichier /etc/hosts

cp /etc/hosts /etc/hosts_sauve_$DATE
OK_SE3=`cat /etc/hosts | grep ###SE3_SERVER###`
if [ "$OK_SE3" == "" ]
then
	echo "###SE3_IP###	###SE3_SERVER###" >> /etc/hosts
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
pam_password md5" > /etc/pam_ldap.conf

# Configuration du fichier /etc/libnss-ldap.conf

cp /etc/libnss-ldap.conf /etc/libnss-ldap_sauve_$DATE.conf
echo "
# /etc/libnss-ldap.conf
# Configuration pour Sambaedu3

 @(#)$Id$

host ###LDAP_SERVER###
base ###BASE_DN###
ldap_version 3
port 389" > /etc/libnss-ldap.conf


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

auth       requisite  pam_nologin.so
auth       required   pam_env.so
@include common-auth
@include common-account
@include common-session
session    required   pam_limits.so
@include common-password" > /etc/pam.d/login

# Configuration du fichier /etc/pam.d/common-auth

cp /etc/pam.d/common-auth /etc/pam.d/common-auth_sauve_$DATE
echo "
# /etc/pam.d/common-auth
# Configuration pour SambaEdu3

auth       optional     pam_mount.so
auth       sufficient   pam_ldap.so    use_first_pass
auth       required     pam_unix.so    use_first_pass" > /etc/pam.d/common-auth

# Configuration du fichier /etc/pam.d/common-account

cp /etc/pam.d/common-account /etc/pam.d/common-account_sauve_$DATE
echo "
# /etc/pam.d/common-account
# Configuration pour SambaEdu3

account    sufficient   pam_ldap.so    use_first_pass
account    required     pam_unix.so    use_first_pass" > /etc/pam.d/common-account

# Configuration du fichier /etc/pam.d/common-session

cp /etc/pam.d/common-session /etc/pam.d/common-session_sauve_$DATE
echo "
# /etc/pam.d/common-session
# Configuration pour SambaEdu3

session    optional     pam_mount.so
session    required     pam_unix.so    use_first_pass" > /etc/pam.d/common-session

# Configuration du fichier /etc/pam.d/common-password

cp /etc/pam.d/common-password /etc/pam.d/common-password_sauve_$DATE
echo "
# /etc/pam.d/common-password
# Configuration pour SambaEdu3

password   required     pam_unix.so    nullok obscure min=8 md5" > /etc/pam.d/common-password

# Configuration du fichier /etc/security/pam_mount.conf

cp /etc/security/pam_mount.conf /etc/security/pam_mount_sauve_$DATE.conf

echo "
# /etc/security/pam_mount.conf
# Configuration pour SambaEdu3

debug 0
mkmountpoint 1
fsckloop /dev/loop7
options_require nosuid,nodev

lsof /usr/sbin/lsof %(MNTPT)
fsck /sbin/fsck -p %(FSCKTARGET)
losetup /sbin/losetup -p0 \"%(before=\\\"-e\\\" CIPHER)\" \"%(before=\\\"-k\\\" KEYBITS)\" %(FSCKLOOP) %(VOLUME)
unlosetup /sbin/losetup -d %(FSCKLOOP)
#cifsmount /bin/mount -t cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
cifsmount /sbin/mount.cifs //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
smbmount /usr/bin/smbmount   //%(SERVER)/%(VOLUME) %(MNTPT) -o \"username=%(USER)%(before=\\\",\\\" OPTIONS)\"
#ncpmount /usr/bin/ncpmount   %(SERVER)/%(USER) %(MNTPT) -o \"pass-fd=0,volume=%(VOLUME)%(before=\\\",\\\" OPTIONS)\"
#ncpumount /usr/bin/ncpumount %(MNTPT)
# Linux supports lazy unmounting (-l).  May be dangerous for encrypted volumes.
# May also break loopback mounts because loopback devices are not freed.
# Need to unmount mount point not volume to support SMB mounts, etc.
# umount   /bin/umount %(MNTPT)
umount /usr/sbin/umountH.sh %(MNTPT)
# On OpenBSD try \"/usr/local/bin/mount_ehd\" (included in pam_mount package).
#lclmount /bin/mount -p0 %(VOLUME) %(MNTPT) \"%(before=\\\"-o\\\" OPTIONS)\"
#cryptmount /bin/mount -t crypt \"%(before=\\\"-o\\\" OPTIONS)\" %(VOLUME) %(MNTPT)
#nfsmount /bin/mount %(SERVER):%(VOLUME) %(MNTPT) \"%(before=\\\"-o\\\" OPTIONS)\"
# --bind may be a Linuxism.  FIXME: find BSD equivalent.
#mntagain /bin/mount --bind %(PREVMNTPT) %(MNTPT)
#mntcheck /bin/mount # For BSD's (don't have /etc/mtab)
#pmvarrun /usr/sbin/pmvarrun -u %(USER) -d -o %(OPERATION)

#volume * cifs ###SE3_SERVER### netlogon /home/netlogon mapchars,serverino,nobrl,iocharset=iso8859-15 - -
volume * cifs ###SE3_SERVER### & /home/& uid=&,gid=&,mapchars,serverino,nobrl,iocharset=iso8859-15 - -
volume * smb ###SE3_SERVER### Classes /home/&/Desktop/Classes uid=&,gid=&,iocharset=iso8859-15 - -
#volume * cifs ###SE3_SERVER### Classes /home/&/Desktop/Classes uid=&,gid=&,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - -
volume * smb ###SE3_SERVER### Progs /home/&/Progs uid=&,gid=&,iocharset=iso8859-15 - -
#volume * cifs ###SE3_SERVER### Progs /home/&/Progs uid=&,gid=&,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - -
volume * smb ###SE3_SERVER### Docs /home/&/Desktop/Partages uid=&,gid=&,iocharset=iso8859-15 - -
#volume * cifs ###SE3_SERVER### Docs /home/&/Desktop/Partages uid=&,gid=&,mapchars,serverino,nobrl,noperm,iocharset=iso8859-15 - - " > /etc/security/pam_mount.conf

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

# Attendre la fin des precessus qui utilisent le répertoire à démonter
until [ ``\`/usr/sbin/lsof \$homeUSER | wc -l\``` = \"0\" ]
        do
                sleep 1
done

# Démontage du repertoire
/bin/umount \$homeUSER" > /usr/sbin/umountH.sh

# Configuration du fichier /etc/login.defs

cp /etc/login.defs /etc/login_sauve_$DATE.defs
perl -pi -e "s/CLOSE_SESSIONS no/CLOSE_SESSIONS yes/" /etc/login.defs

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
echo -e "\033[1;31m"
echo "ATTENTION : Seul les comptes ayant un shell peuvent se connecter"
echo -e "\033[1;37m"
