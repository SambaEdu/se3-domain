#!/bin/bash
#
##### Script generant les scripts pour configurer un client SE3#####
#
# Auteur : Mickael POIRAULT Mickael.Poirault@ac-poitiers.fr
# modif keyser : integration au paquet se3-domain
## $Id$ ##

if [ "$1" == "--help" -o "$1" == "-h" ]
then
        echo "Permet de générer les scripts pour configurer un client SE3"
	echo "Ubuntu 6.xx A 9.10 - Debian Sarge et Etch"
        echo "Une fois générés les scripts sont placés dans le répertoire /root/"
        echo "Usage :    ./create_client.sh"
        echo "        Pour permettre à tous les comptes autorisés à accéder en root à se3"
		echo "        d'accéder aussi aux clients linux:"
        echo "           ./create_client.sh ssh_full"

	echo "Ce script est distribué selon les termes de la licence GPL"
        echo "--help cette aide"

        exit
fi




# recuperation params config, ldap et masques
. /usr/share/se3/includes/config.inc.sh -clm

BASE_DN="$ldap_base_dn"
NTPSERVERS="$ntpserv"
LDAP_SERVER="$ldap_server"
SE3_SERVER=`echo $HOSTNAME`
PASSADM="$xppass"
PASSADMCRYPT=$(echo "$PASSADM" | makepasswd --clearfrom=- --crypt-md5 |awk '{ print $2 }')

# Debug:
#echo "PASSADM=$PASSADM"
#echo "PASSADMCRYPT=$PASSADMCRYPT"


NTPOPTIONS=`cat /etc/default/ntpdate | grep -v "#NTPOPTIONS" | grep "NTPOPTIONS" | sed 's/\"/\\\"/g'| sed 's/\"/\\\\"/g'`


if `cat /etc/samba/smb.conf | grep -v "#" | grep "ISO8859-15" >/dev/null`
then
	IOCHARSET="iso8859-15"
else
	if `cat /etc/samba/smb.conf | grep -v "#" | grep "UTF-8" >/dev/null`
	then
		IOCHARSET="utf8"
	else
		echo "Impossible de déterminer le jeu de caractères utilisé par samba"
		echo "Par défaut la valeur utilisée sera iso8859-15"
		IOCHARSET="iso8859-15"
	fi
fi

# Test la presence de la cle publique, et la copie dans /var/www/se3
if [ -e "/root/.ssh/authorized_keys" -a -n "$(echo $*|grep ssh_full)" ]
then
        cp /root/.ssh/authorized_keys /var/www/se3/authorized_keys
		if [ -e "/root/.ssh/id_rsa.pub" ]
		then
			cat /root/.ssh/id_rsa.pub >> /var/www/se3/authorized_keys
		fi
        chown www-se3 /var/www/se3/authorized_keys
        chmod 400 /var/www/se3/authorized_keys
else
	if [ -e "/root/.ssh/id_rsa.pub" ]
	then
			cp /root/.ssh/id_rsa.pub /var/www/se3/authorized_keys
			chown www-se3 /var/www/se3/authorized_keys
			chmod 400 /var/www/se3/authorized_keys
	fi
fi



# Cas ou LDAP_SERVEUR = 127.0.0.1
if [ "$LDAP_SERVER" = "127.0.0.1" ]
then
	LDAP_SERVER="$se3ip"
fi

# Test TLS
TLS=`grep TLS /etc/ldap/slapd.conf > /dev/null && echo 1`


# Modifie les scripts
perl -pi -e "s/###BASE_DN###/$BASE_DN/" /root/rejoint_se3_*.sh
perl -pi -e "s/###LDAP_SERVER###/$LDAP_SERVER/" /root/rejoint_se3_*.sh
perl -pi -e "s/###SE3_IP###/$se3ip/" /root/rejoint_se3_*.sh
perl -pi -e "s/###SE3_SERVER###/$SE3_SERVER/" /root/rejoint_se3_*.sh
perl -pi -e "s/###NTPSERVERS###/$NTPSERVERS/" /root/rejoint_se3_*.sh
perl -pi -e "s/###NTPOPTIONS###/$NTPOPTIONS/" /root/rejoint_se3_*.sh
perl -pi -e "s/###IOCHARSET###/$IOCHARSET/" /root/rejoint_se3_*.sh
if [ -n "$PASSADMCRYPT" ]; then
	#perl -pi -e "s|###PASSADMCRYPT###|$(echo $PASSADMCRYPT |tr '#' '$')|" /root/rejoint_se3_*.sh
	#perl -pi -e "s|###PASSADMCRYPT###|$PASSADMCRYPT|" /root/rejoint_se3_*.sh
	sed -i "s|###PASSADMCRYPT###|$PASSADMCRYPT|" /root/rejoint_se3_*.sh
	# Debug:
	#grep "^PASSADMCRYPT=" /root/rejoint_se3_*.sh
fi

if [ "$TLS" = "1" ]
then
		perl -pi -e "s/###TLS###/$TLS/" /root/rejoint_se3_*.sh
fi

chmod +x /root/rejoint_se3_*.sh



