#!/bin/bash
#
# 
########################################################################
##### Script permettant de joindre un client ubuntu au serveur SE3 #####
##### version du 17 mars 2010
#
# Auteur : Mickael POIRAULT Mickael.Poirault@ac-poitiers.fr
# Modifie par JC Mousseron pour la version Ubuntu 9.10
# Modifie par Philippe Peter pour:
# -integration Kubuntu 9.10
# -choix du nom de la machine 
# -rendre Administrateur SE3 sudo root
# -désactiver l'affichage des utilisateurs antérieurs pour Ubuntu, Xubuntu et Ubuntu-netbook-remix
# -remontée éventuelle dans l'inventaire OCS du SE3
# -ajout de nscd
# -ajout de cron.apt pour que l'installation des maj de securite se fasse automatiquement
# -test renseignement variables
# -passage d'arguments au script
# -rapport d'integration horodaté nommé SE3_rapport_integration_UXuKubuntu-9.10 dans le /root de la machine Buntu

# Tests effectues avec Ubuntu 9.10, Kubuntu 9.10, Xubuntu 9.10, Ubuntu-netbook-remix9.10 et version alpha3 Ubuntu 10.04
# sur des serveurs SE3 Sarge 1.15.12 ou Etch 1.18.2 ou 1.5
#   
########################################################################

DATERAPPORT=$(date +%F+%0kh%0Mmin)

{

# Section a completer avec vos parametres ! 
SE3_SERVER="###SE3_SERVER###"
SE3_IP="###SE3_IP###"
BASE_DN="###BASE_DN###"
LDAP_SERVER="###LDAP_SERVER###"
NTPSERVERS="###NTPSERVER###"
NTPOPTIONS="###NTPOPTIONS###"
TLS="###TLS###"
IOCHARSET="###IOCHARSET###"
##########################################

# aide obtenue avec passage des arguments --help ou -h à l'appel du script

if [ "$1" == "--help" -o "$1" == "-h" ]; then
	echo ""
	echo "-----------------------------------------------"
	echo "AIDE concernant l'utilisation du script d'integration des clients Buntu sur le serveur SAMBA EDU 3"
	echo "Ce script permet de faire rejoindre un client ubuntu au serveur SE3."
	echo "Les tests ont ete effectues avec Ubuntu 9.10, Xubuntu9.10, Ubuntu-netbook-remix9.10, Kubuntu 9.10 et Ubuntu10.04 version alpha3 avec des serveurs Samba Edu3 Sarge ou Etch.  "
	echo "Ce script est a lancer sur le client en root via la commande sudo:"
    echo "Exemple: sudo $0" 
	echo "Des arguments peuvent être passés à l'appel du script, lire la suite..."
	echo ""
	echo "-----------------------------------------------"
	echo ""
	echo "Les donnees indiquées dans le script sont :"
	echo "  $SE3_SERVER : nom du serveur Se3"
	echo "  $SE3_IP : ip du serveur Se3"
	echo "  $BASE_DN : base dn de l'annuaire"
	echo "  $LDAP_SERVER : addresse du serveur ldap"
	echo "  $NTPSERVERS : serveur de temps pour ntpdate"
	echo "  $NTPOPTIONS : options pour ntpdate"
	echo "  $TLS : options TLS pour le serveur ldap"
	echo "  $IOCHARSET : locale pour pam_mount.conf.xml"
	echo ""
	echo "A la suite de l'execution du script un rapport nommé SE3_rapport_integration_UXuKubuntu-9.10_date sera disponible dans le dossier /root du client Buntu."
	echo ""
	echo "-----------------------------------------------"
	echo ""
	echo "Usage n°1: Appel du script sans argument"
	echo "Commande à saisir: $0"
	echo "Exemple: $0" 
	echo "Le script demandera:"
	echo "-le nom de la machine"
	echo "-la possibilité d installer automatiquement les mises à jour de sécurité"
	echo "-la possibilité de remonter les informations de la machine dans l inventaire du SE3"
	echo "-la possibilité de redémarrer la machine à la fin de son intégration."
	echo ""
	echo "Dans les possibilités suivantes de passage d'arguments au lancement du script la logique est la suivante:"
	echo "-si le script a un premier argument en appel c'est le nom_de_la_machine"
	echo "-et par défaut pas d installation des maj de sécurité sauf si l'on positionne le second argument à o"
	echo "-et par défaut remontée des infos de la machine dans l'inventaire sauf si l'on positionne le troisième argument à n"
	echo "-et par défaut redémarrage de la machine à la fin de l intégration sauf si l'on positionne le quatrième argument à n."
	echo ""
	echo "Usage n°2: Appel du script avec un seul argument"
	echo "Commande à saisir: $0 nomdelamachine"
	echo "Exemple: $0 superbuntu" 
	echo "installera la machine avec le nom superbuntu SANS automatisation de l installation des màj de sécurité, AVEC remontée des infos dans l'inventaire et AVEC redemarrage automatique."
	echo ""
	echo "Usage n°3: Appel du script avec deux arguments"
	echo "Commande à saisir: $0 nomdelamachine o"
	echo "Exemple: $0 superbuntu o" 
	echo "installera la machine avec le nom superbuntu AVEC automatisation de l installation des màj de sécurité, et AVEC remontée des infos dans l'inventaire et AVEC redemarrage automatique."
	echo ""
	echo "Usage n°4: Appel du script avec trois arguments"
	echo "Commande à saisir: $0 nomdelamachine o n"
	echo "Exemple: $0 superbuntu o n" 
	echo "installera la machine avec le nom superbuntu AVEC automatisation de l installation des màj de sécurité, et SANS remontée des infos dans l'inventaire et AVEC redemarrage automatique."
	echo ""
	echo "Usage n°5: Appel du script avec quatre arguments"
	echo "Commande à saisir: $0 nomdelamachine o n n"
	echo "Exemple: $0 superbuntu o n n"
    echo "installera la machine avec le nom superbuntu AVEC automatisation de l installation des màj de sécurité, et SANS remontée des infos dans l'inventaire et SANS redemarrage automatique."
	echo ""
	echo "-----------------------------------------------"
	echo ""
	echo "Différences entre Ubuntu9.10, Xubuntu9.10, Kubuntu9.10 et Ubuntu-netbook-remix9.10:"
	echo ""
    echo "Pour Ubuntu9.10:"
    echo "tous les partages réseaux apparaissent sur le bureau."
	echo "Par souci de clarification les partages réseaux ou dossiers se trouvant sur le serveur SE3 sont nommés avec le suffixe _SE3."
	echo ""
    echo "Pour Xubuntu9.10:"
    echo "le répertoire personnel apparaît sur le bureau"
    echo "pour les autres partages réseau cliquer sur l'icone « système de fichiers » puis media et le dossier au nom de l'utilisateur"
	echo "Par souci de clarification les partages réseaux ou dossiers se trouvant sur le serveur SE3 sont nommés avec le suffixe _SE3."
	echo ""
    echo "Pour Kubuntu9.10:"
    echo "le répertoire personnel apparaît dans « Poste de travail », il se nomme « Dossier personnel »"
    echo "pour les autres partages réseau cliquer sur l'icone « Poste de travail » puis racine puis media et le dossier au nom de l'utilisateur"
	echo "Par souci de clarification les partages réseaux ou dossiers se trouvant sur le serveur SE3 sont nommés avec le suffixe _SE3."
	echo ""
    echo "Ubuntu-netbook-remix9.10:"
    echo "cliquer sur « Fichiers et Dossiers » dans la barre latérale de gauche. Puis cliquer sur n'importe quel dossier et utiliser le menu « Aller à » ou bien « Affichage/panneau latéral » et vous accéderez aux partages réseaux."
	echo "Par souci de clarification les partages réseaux ou dossiers se trouvant sur le serveur SE3 sont nommés avec le suffixe _SE3."
	echo ""
	echo "-----------------------------------------------"
	echo ""
	echo "Des arguments peuvent être passés à l'appel du script, lire plus haut les exmples d'usage."
	echo ""
	echo "-----------------------------------------------"
	exit 0
fi

# test renseignement variables fondamentales

#if [ $SE3_SERVER = "###SE3_SERVER###" ]; then
if [ -z "${SE3_SERVER}" -o "${SE3_SERVER:0:1}" = "#" ]; then
echo " Erreur: la variable SE3_SERVER n'est pas renseignée."
exit
fi

#if [ $SE3_IP = "###SE3_IP###" ]; then
if [ -z "${SE3_IP}" -o "${SE3_IP:0:1}" = "#" ]; then
echo " Erreur: la variable SE3_IP n'est pas renseignée."
exit
fi

#if [ $BASE_DN = "###BASE_DN###" ]; then
if [ -z "$BASE_DN" -o "$BASE_DN" = "#" ]; then
echo " Erreur: la variable BASE_DN n'est pas renseignée."
exit
fi

#if [ $LDAP_SERVER = "###LDAP_SERVER###" ]; then
if [ -z "${LDAP_SERVER}" -o "${LDAP_SERVER:0:1}" = "#" ]; then
echo " Erreur: la variable LDAP_SERVER n'est pas renseignée."
exit
fi

# attribution des arguments eventuels passés en ligne de commande 
# par défaut:
# - pas d'automatisation de l'installation des mises à jour de sécurité
# - remontée des infos machine Buntu dans l'inventaire (que le module inventaire OCS soit activé ou non sur le SE3)
# - redémarrage automatique en fin d'intégration de la machine Buntu

CRONAPT=n 
OCS=o
REBOOT=o

# affichage date version script

echo "La version du script utilisé est datée du 17 mars 2010."

# test des arguments passés à l'appel du script

case "$#" in
  0)
		echo "Aucun paramètre passé en appel du script."
		echo "Quel nom choisissez-vous pour cette machine?"
		read NOMMACH
		echo "Le nom choisi pour la machine est $NOMMACH."
		echo "Voulez-vous configurer la machine pour que les mises à jour de securite soient effectuees automatiquement?"
		PS3='Répondre par o ou n:'   # le prompt
		LISTE=("[o] oui" "[n]  non")  # liste de choix disponibles
		select CHOIX in "${LISTE[@]}" ; do
			case $REPLY in
				1|o)
				echo "Vous avez choisi l installation automatique des mises à jour de securite."
				CRONAPT=o
				break
				;;
				2|n)
				echo "Vous avez refuse l installation automatique des mises à jour de securite."
				CRONAPT=n
				break
				;;
			esac
		done

		echo "A la fin de l'installation, voulez-vous une remontée des informations dans l'inventaire du serveur SE3?"
		PS3='Répondre par o ou n:'   # le prompt
		LISTE=("[o] oui" "[n]  non")  # liste de choix disponibles
		select CHOIX in "${LISTE[@]}" ; do
			case $REPLY in
				1|o)
				echo "Vous avez choisi la remontee des infos de la machine dans l'inventaire."
				OCS=o
				break
				;;
				2|n)
				echo "Vous avez refuse la remontee des infos de la machine dans l'inventaire."
				OCS=n
				break
				;;
			esac
		done

		echo "A la suite de l'integration de la machine, voulez-vous qu'elle redémarre automatiquement?"
		PS3='Répondre par o ou n:'   # le prompt
		LISTE=("[o] oui" "[n]  non")  # liste de choix disponibles
		select CHOIX in "${LISTE[@]}" ; do
			case $REPLY in
				1|o)
				echo "Vous avez choisi le redémarrage automatique de la machine."
				REBOOT=o
				break
				;;
				2|n)
				echo "Vous avez refuse le redémarrage automatique de la machine."
				REBOOT=n
				break
				;;
			esac
		done
      ;;
	1)
		echo "Le nom de la machine choisi est $1"
		echo "En l'absence d'autres arguments:"
		echo "-l'automatisation de l'installation des mises à jour de sécurité n'aura pas lieu"
		echo "-une tentative de remontée des infos du client dans l'inventaire OCS du SE3 aura lieu"
		echo "-le redémarrage automatique du client Buntu aura lieu après son intégration." 
		NOMMACH=$1
	;;
	2)
		echo "Le nom de la machine  choisi est $1 et vous avez répondu: "
		echo "$2 pour l'automatisation de l'installation des mises à jour de sécurité CRONAPT"
		echo "-une tentative de remontée des infos du client dans l'inventaire OCS du SE3 aura lieu"
		echo "-le redémarrage automatique du client Buntu aura lieu après son intégration."
		NOMMACH=$1
		if [ $2 = "o" ] || [ $2 = "n" ];then
		CRONAPT=$2
		else
		echo "Le second argument n'est pas valable. Il ne peut être que o ou n."
		exit
		fi
	;;
	3)
		echo "Le nom de la machine  choisi est $1 et vous avez répondu: "
		echo "$2 pour l'automatisation de l'installation des mises à jour de sécurité CRONAPT"
		echo "$3 pour la remontée des infos du client dans l'inventaire OCS du SE3"
		echo "-le redémarrage automatique du client Buntu aura lieu après son intégration."
		NOMMACH=$1
		if [ $2 = "o" ] || [ $2 = "n" ];then
		CRONAPT=$2
		else
		echo "Le second argument n'est pas valable. Il ne peut être que o ou n."
		exit
		fi
		if [ $3 = "o" ] || [ $3 = "n" ];then
		OCS=$3
		else
		echo "Le troisième argument n'est pas valable. Il ne peut être que o ou n."
		exit
		fi
	;;
	4)
		echo "Le nom de la machine  choisi est $1 et vous avez répondu: "
		echo "$2 pour l'automatisation de l'installation des mises à jour de sécurité CRONAPT"
		echo "$3 pour la remontée des infos du client dans l'inventaire OCS du SE3"
		echo "$4 pour le redémarrage automatique du client Buntu après son intégration."
		NOMMACH=$1
		if [ $2 = "o" ] || [ $2 = "n" ];then
		CRONAPT=$2
		else
		echo "Le second argument n'est pas valable. Il ne peut être que o ou n."
		exit
		fi
		if [ $3 = "o" ] || [ $3 = "n" ];then
		OCS=$3
		else
		echo "Le troisième argument n'est pas valable. Il ne peut être que o ou n."
		exit
		fi
		if [ $4 = "o" ] || [ $4 = "n" ];then
		REBOOT=$4
		else
		echo "Le quatrième argument n'est pas valable. Il ne peut être que o ou n."
		exit
		fi
	
esac

# test presence caractere interdit dans le nom de la machine

test="$(echo $NOMMACH | sed -e 's/[^[:alnum:]]//g')"
if [ "$test" != "$NOMMACH" ] ; then
echo "Erreur: le nom choisi pour la machine $NOMMACH contient un caractère non alphanumérique."
exit
else
echo "C'est bon: le nom choisi de la machine $NOMMACH ne contient que des caractères alphanumériques."
fi


# comment rendre le script "cretin-resistant", par Christian Westphal

TEST_CLIENT=`ifconfig | grep ":$SE3_IP "`
if [ ! -z "$TEST_CLIENT" ]; then
	echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur."
	exit
fi

[ -e /var/www/se3 ] && echo "Malheureux... Ce script est a executer sur les clients Linux, pas sur le serveur." && exit 1


# Recuperation de la date et de l'heure pour la sauvegarde des fichiers

DATE=$(date +%F+%0kh%0Mmin)

# Modification du fichier /etc/apt/sources.list

echo "Modification du /etc/apt/sources.list"

cp /etc/apt/sources.list /etc/apt/sources.list_sauve_$DATE
perl -pi -e "s&deb cdrom&# deb cdrom&" /etc/apt/sources.list

# Mise a jour de la machine

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=high

echo "Mise a jour de la machine..."

# Resolution du probleme de lock

if [ -e "/var/lib/dpkg/lock" ]; then
	rm -f /var/lib/dpkg/lock
fi

# On lance une maj

apt-get update
apt-get dist-upgrade -y

# On rechange le sources.list

perl -pi -e 's&^#.*deb http://(.*)universe$&deb http://$1 universe&' /etc/apt/sources.list
perl -pi -e 's&^# deb-src http://(.*)universe$&deb-src http://$1 universe&' /etc/apt/sources.list
perl -pi -e 's&^#.*deb http://(.*)restricted$&deb http://$1 restricted&' /etc/apt/sources.list

apt-get update

# Installation des paquets necessaires

echo "Installation des paquets necessaires:"

echo "Ne rien remplir, les fichiers sont configures/modifies automatiquement apres..."

apt-get install --assume-yes libnss-ldap  libpam-ldap lsof libpam-mount smbfs samba-common ntpdate ssh ocsinventory-agent ldap-utils nscd cron-apt

# Configuration des fichiers

echo "Configuration des fichiers pour Samba Edu 3..."

# Configuration du fichier /etc/hosts


echo "Configuration du fichier /etc/hosts"

cp /etc/hosts /etc/hosts_sauve_$DATE
OK_SE3=`cat /etc/hosts | grep $SE3_SERVER`
if [ -z "$OK_SE3" ]; then
	echo "$SE3_IP	$SE3_SERVER" >> /etc/hosts
fi

# Configuration du fichier /etc/ldap.conf

echo "Configuration du fichier /etc/ldap.conf"

cp /etc/ldap.conf /etc/ldap.conf_sauve_$DATE
echo "
# /etc/ldap.conf
# Configuration pour Sambaedu3

host $LDAP_SERVER
base $BASE_DN
ldap_version 3
port 389
bind_policy soft
pam_password md5" > /etc/ldap.conf

# Verification présence du nom machine choisi dans le LDAP

ldapsearch -h $SE3_SERVER -b "ou=Computers,$BASE_DN" -xL cn=$NOMMACH > resultat_recherche_nom_machine_annuaire && echo "La recherche de la présence du nom dans l annuaire a eu lieu:" &
wait
grep -wq numEntries resultat_recherche_nom_machine_annuaire
if [ $? -eq 0 ]
then 
echo "Ce nom est déjà utilisé."
echo "----------------------"
cat resultat_recherche_nom_machine_annuaire
echo "----------------------"
echo ""
echo "Relancez le script, en choisissant un nom de machine non présent dans l'annuaire :-)"
exit 0
else
echo "Ce nom n'est pas utilisé, donc le script continue."	
ANCIENNOM=$(hostname)
cp /etc/hosts /etc/hosts_sauve_$DATE
sed "s/$ANCIENNOM/$NOMMACH/g" /etc/hosts
cp /etc/hostname /etc/hostname_sauve_$DATE
echo "$NOMMACH" > /etc/hostname
fi

# Configuration du fichier /etc/nsswitch.conf

echo "Configuration du fichier /etc/nsswitch.conf"

cp /etc/nsswitch.conf /etc/nsswitch.conf_sauve_$DATE
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

echo "Configuration du fichier /etc/pam.d/login"

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

echo "Configuration du fichier /etc/pam.d/common-auth"

cp /etc/pam.d/common-auth /etc/pam.d/common-auth_sauve_$DATE
echo "
# /etc/pam.d/common-auth
# Configuration pour SambaEdu3

auth	optional	pam_group.so
auth	optional	pam_mount.so
auth	sufficient	pam_ldap.so    use_first_pass
auth	required	pam_unix.so    use_first_pass" > /etc/pam.d/common-auth

# Configuration du fichier /etc/pam.d/common-account

echo "Configuration du fichier /etc/pam.d/common-account"

cp /etc/pam.d/common-account /etc/pam.d/common-account_sauve_$DATE
echo "
# /etc/pam.d/common-account
# Configuration pour SambaEdu3

session required	pam_mkhomedir.so	skel=/etc/skel/
account	sufficient	pam_ldap.so	use_first_pass
account	required	pam_unix.so	use_first_pass" > /etc/pam.d/common-account

# Configuration du fichier /etc/pam.d/common-session

echo "Configuration du fichier /etc/pam.d/common-session"

cp /etc/pam.d/common-session /etc/pam.d/common-session_sauve_$DATE
echo "
# /etc/pam.d/common-session
# Configuration pour SambaEdu3

session	optional	pam_mount.so
session	required	pam_unix.so	use_first_pass" > /etc/pam.d/common-session

# Configuration du fichier /etc/pam.d/common-password

echo "Configuration du fichier /etc/pam.d/common-password"

cp /etc/pam.d/common-password /etc/pam.d/common-password_sauve_$DATE
echo "
# /etc/pam.d/common-password
# Configuration pour SambaEdu3

password	required	pam_unix.so	nullok obscure min=8 md5" > /etc/pam.d/common-password

# Configuration du fichier /etc/pam.d/sudo

echo "Configuration du fichier /etc/pam.d/sudo"

cp /etc/pam.d/sudo /etc/pam.d/sudo_sauve_$DATE
echo "
# /etc/pam.d/sudo
# Configuration pour SambaEdu3
# Modifie par P.Peter pour permettre a admin (Administrateur SE3) de sudoifier

@include common-auth
@include common-account" > /etc/pam.d/sudo

#ajout de admin a la liste des suoders avec pouvoir de root

cp -a /etc/sudoers /etc/sudoers_sauve_$DATE
sed -i '/root /a\admin	ALL=(ALL) ALL' /etc/sudoers

# Configuration du fichier /etc/security/group.conf

echo "Configuration du fichier /etc/security/group.conf"

cp /etc/security/group.conf /etc/security/group.conf_sauve_$DATE
echo "
# /etc/security/group.conf
# Configuration pour SambaEdu3

gdm;*;*;Al0000-2400;floppy,cdrom,audio,video,plugdev
kdm;*;*;Al0000-2400;floppy,cdrom,audio,video,plugdev" > /etc/security/group.conf

# Configuration du fichier /etc/pam.d/common-pammount
# indispensable pour Kubuntu et fonctionnant avec Ubuntu et Xubuntu

echo "Configuration du fichier /etc/pam.d/common-pammount"

touch /etc/pam.d/common-pammount
echo "
# /etc/pam.d/common-pammount
# Configuration pour SambaEdu3 et Kubuntu et Ubuntu et Xubuntu et Ubuntu-netbook-remix

auth	optional	pam_mount.so use_first_pass
session	optional	pam_mount_so" > /etc/pam.d/common-pammount

if [ -f /etc/pam.d/kdm ];then
echo "
@include common-pammount">> /etc/pam.d/kdm
fi
if [ -f /etc/pam.d/gdm ];then
echo "
@include common-pammount">> /etc/pam.d/gdm
fi

# Correction du bug eventuel KDE Intel de retour en tty à la deconnexion de session

if [ -f /etc/kde4/kdm/kdmrc ];then
cp /etc/kde4/kdm/kdmrc /etc/kde4/kdm/kdmrc_sauve_$DATE
sed -i '/ServerCmd/a\TerminateServer=true' /etc/kde4/kdm/kdmrc
fi
# Desactivation de l affichage de la liste des utilisateurs antérieurs

if [ -f /usr/bin/gconftool-2 ];then
sudo -u gdm gconftool-2 -t bool -s /apps/gdm/simple-greeter/disable_user_list true
fi

# Configuration du fichier /etc/security/pam_mount.conf.xml

echo "Configuration du fichier /etc/security/pam_mount.conf.xml"

cp /etc/security/pam_mount.conf.xml /etc/security/pam_mount.conf.xml_sauve_$DATE
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<!--
/etc/security/pam_mount.conf.xml
Configuration pour SambaEdu3
-->

<pam_mount>
<debug enable=\"1\" />
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
<umount>umount.cifs %(MNTPT)</umount>


<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"netlogon\" mountpoint=\"/home/netlogon\" user=\"*\" options=\"mapchars,serverino,nobrl,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"%(USER)/Docs\" mountpoint=\"/home/%(USER)/Documents_SE3\" user=\"*\" options=\"uid=%(USER),gid=admins,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />


#<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"%(USER)/profil\" mountpoint=\"/home/%(USER)/profil\" user=\"*\" options=\"uid=%(USER),gid=admins,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
#<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Classes\" mountpoint=\"/media/%(USER)/Classes\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Classes\" mountpoint=\"/home/%(USER)/Classes_SE3\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />

#<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Docs\" mountpoint=\"/media/%(USER)/Partages\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Docs\" mountpoint=\"/home/%(USER)/Partage_Docs_SE3\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
#<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"%(USER)/profil/Bureau\" mountpoint=\"/home/%(USER)/Bureau\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />

# ajout Philippe Peter car Progs peut etre utile à tous (avec wine) et admse3 et admhomes utiles a l'administrateur du se3
#<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Progs\" mountpoint=\"/media/%(USER)/Progs\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
#<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"admse3\" mountpoint=\"/media/%(USER)/admse3\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
#<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"admhomes\" mountpoint=\"/media/%(USER)/admhomes\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />

<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"Progs\" mountpoint=\"/home/%(USER)/Progs_SE3\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"admse3\" mountpoint=\"/home/%(USER)/admse3_SE3\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />
<volume fstype=\"cifs\" server=\"$SE3_SERVER\" path=\"admhomes\" mountpoint=\"/home/%(USER)/admhomes_SE3\" user=\"*\" options=\"uid=%(USER),gid=admins,setuids,mapchars,serverino,nobrl,noperm,iocharset=$IOCHARSET\" />

# fin ajout

<msg-authpw>Mot de passe :</msg-authpw>
<msg-sessionpw>Mot de passe :</msg-sessionpw>

</pam_mount>" > /etc/security/pam_mount.conf.xml

killall trackerd 2>/dev/null
killall bluetooth-applet 2>/dev/null

# Configuration du fichier /etc/default/ntpdate

echo "Configuration du fichier /etc/default/ntpdate"

cp /etc/default/ntpdate /etc/default/ntpdate_sauve_$DATE
echo "
# /etc/default/ntpdate
# Configuration pour SambaEdu3
# servers to check.   (Separate multiple servers with spaces.)
NTPSERVERS=\"$NTPSERVERS\"
#NTPSERVERS=\"$SE3_SERVER\"

# additional options for ntpdate

$NTPOPTIONS" > /etc/default/ntpdate

# On recupere la cle publique du serveur

mkdir -p /root/.ssh
chmod 700 /root/.ssh
cd /root/.ssh
if [ -f "authorized_keys" ];then
wget -o log_recuperation_cle_pub_se3_$DATE -O authorized_keys_se3 $SE3_IP:909/authorized_keys
cat authorized_keys_se3 >> authorized_keys
else
wget -o log_recuperation_cle_pub_se3_$DATE -O authorized_keys $SE3_IP:909/authorized_keys
fi
chmod 400 /root/.ssh/authorized_keys
cd /

# Configuration du fichier /etc/nscd.conf

echo "Configuration du fichier /etc/nscd.conf"

cp /etc/nscd.conf /etc/nscd.conf_sauve_$DATE
echo "
#  Fichier de conf pour le Samba Edu 3
# /etc/nscd.conf

	logfile			/var/log/nscd.log
	debug-level		0
#	reload-count		5
	paranoia		no
#	restart-interval	3600

	enable-cache		passwd		yes
	positive-time-to-live	passwd		1200
	negative-time-to-live	passwd		20
	suggested-size		passwd		211
	check-files		passwd		yes
	persistent		passwd		yes
	shared			passwd		yes
	max-db-size		passwd		33554432
	auto-propagate		passwd		yes

	enable-cache		group		yes
	positive-time-to-live	group		3600
	negative-time-to-live	group		60
	suggested-size		group		211
	check-files		group		yes
	persistent		group		yes
	shared			group		yes
	max-db-size		group		33554432
	auto-propagate		group		yes

# hosts caching is broken with gethostby* calls, hence is now disabled
# per default.  See /usr/share/doc/nscd/NEWS.Debian.
	enable-cache		hosts		no
	positive-time-to-live	hosts		3600
	negative-time-to-live	hosts		20
	suggested-size		hosts		211
	check-files		hosts		yes
	persistent		hosts		yes
	shared			hosts		yes
	max-db-size		hosts		33554432

	enable-cache		services	yes
	positive-time-to-live	services	28800
	negative-time-to-live	services	20
	suggested-size		services	211
	check-files		services	yes
	persistent		services	yes
	shared			services	yes
	max-db-size		services	33554432
" > /etc/nscd.conf

# Configuration de /etc/cron-apt pour n'installer que les maj de securite

if [ $CRONAPT = "o" ] ; then
echo "Configuration de /etc/cron-apt"

less /etc/apt/sources.list|grep security > /etc/apt/security.sources.list

cp /etc/cron-apt/config /etc/cron-apt/config_sauve_$DATE
echo "
# /etc/cron-apt/config
# Configuration pour SambaEdu3

OPTIONS=\"-o quiet=1 -o Dir::Etc::SourceList=/etc/apt/security.sources.list\"
" > /etc/cron-apt/config

echo "
# Configuration pour Samba Edu3

dist-upgrade -y -o APT::Get::Show-Upgraded=true
" > /etc/cron-apt/action.d/5-install

ln -s /usr/sbin/cron-apt /etc/cron.daily/cron-apt
fi

# On remonte un rapport ocsinventory si admin d'accord

if [ $OCS = "o" ] ; then
echo "Debut de la tentative de remontée dans l'inventaire du SE3."	
ocsinventory-agent --server http://$SE3_IP:909/ocsinventory/ 2>&1
echo "La tentative de remontée dans l inventaire du SE3 a eu lieu."
fi

# Fin de la configuration

echo "Fin de l'installation."

echo "ATTENTION : Seul les comptes ayant un shell peuvent se connecter"
echo ""
echo "Vous devez configurer les locale pour etre compatible avec Se3"
echo "Il faut redémarrer la machine." 


export DEBIAN_FRONTEND=dialog
if [ $REBOOT = "n" ];then
exit 
fi
reboot

} | tee /root/SE3_rapport_integration_UXuKubuntu-9.10_$DATERAPPORT

# si argument d'appel du script est --help ou -h effacement du rapport inutile de l'aide

if [ "$1" == "--help" -o "$1" == "-h" ]; then
rm /root/SE3_rapport_integration_UXuKubuntu-9.10_$DATERAPPORT
fi
exit 0
