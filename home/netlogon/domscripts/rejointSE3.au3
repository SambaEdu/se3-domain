; Script de mise au domaine manuelle
; $Id$
; Stephane Boireau, d'après le script rejointSE3.cmd de Denis Bonnenfant
; N'est normalement lancé qu'en cas d'adhésion 'un nouveau poste
; ou que la mise au domaine depuis l'interface SE3 a échoué.
; Olivier Lacroix : ce script ne contient plus que les accès réseaux à \\se3\netlogon notamment.
; les autres commandes à passer en environnement privilégié sont dans rejointSE3-elevated.exe appelé en fin de ce script.
; Derniere modification: 17/12/2011

;Include constants
#include <GUIConstants.au3>

#include <se3_crob.lib.au3>

; Recuperation des parametres dans le même dossier
$SE3_IP=IniRead(@ScriptDir & "\se3ip.ini", "ParamSE3", "se3ip", "")
$SE3_NETBIOS_NAME=IniRead(@ScriptDir & "\se3ip.ini", "ParamSE3", "netbios_name", "")
$DOMAINE=IniRead(@ScriptDir & "\se3ip.ini", "ParamSE3", "se3_domain", "")
;MsgBox(0,"Info","DOMAINE=" & $DOMAINE)
;Exit

If $SE3_IP = "" Then
	MsgBox(0,"ERREUR", "La variable $SE3_IP est vide." & @CRLF & "Le fichier " & @ScriptDir & "\se3ip.ini est-il renseigné?")
	Exit
EndIf

If $SE3_NETBIOS_NAME = "" Then
	MsgBox(0,"ERREUR", "La variable $SE3_NETBIOS_NAME est vide." & @CRLF & "Le fichier " & @ScriptDir & "\se3ip.ini est-il renseigné?")
	Exit
EndIf

$IP=_GetIP()
If $IP = "" Then
	MsgBox(0,"ERREUR", "L'adresse IP du poste n'a pas été trouvée.")
	Exit
EndIf

SplashTextOn("Informations SE3","Le serveur de fichiers SE3 se nomme " & $SE3_NETBIOS_NAME & @CRLF & "Son adresse IP est " & $SE3_IP & @CRLF & @CRLF & "L'adresse IP actuelle du poste Window$ est " & $IP,500,100,-1,0)
Sleep(3000)

$SystemDrive=_GetSystemDrive()
DirCreate($SystemDrive & "\netinst")

$old_way="n"
If $old_way == "y" Then
	;$cible_netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogonzblouc" ; Pour simuler/forcer l'echec de l'acces sans lecteur
	$cible_netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogon"
	$run=RunWait(@ComSpec & " /c net use " & $cible_netlogon, @SW_SHOW)
	;MsgBox(0,"Info","La tentative d'accès à " & $cible_netlogon & " a retourné " & $run)
	; Le test n'est pas fiable
	;If $run <> 0 Then
	If Not FileExists($cible_netlogon & "\domscripts\se3.cmd") Then

		SplashTextOn("ERREUR","Il n'a pas été possible d'accéder à \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "Vous avez bien fourni le couple (admin;motdepasse) pour accéder à \\" & $SE3_NETBIOS_NAME & "\Progs\install\domscripts, n'est-ce pas ?",500,100,-1,0)
		Sleep(4000)
		SplashTextOn("Nouvelle tentative","Nouvelle tentative en montant un lecteur réseau.",500,100,-1,0)
		Sleep(2000)

		$LECTEUR=_chercher_lecteur_libre()

		$TEST_netlogon=_chercher_lecteur_reseau("NETLOGON")
		If $TEST_netlogon <> "" Then
			$LECTEUR=$TEST_netlogon
			$menage=RunWait(@Comspec & " /c net use " & $LECTEUR & ": /delete /y")
		EndIf

		;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		; Il faut réclamer le nom de domaine et le mot de passe admin
		;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		If $DOMAINE == "" Then
			$DOMAINE=InputBox("Informations supplémentaires","Nom de domaine: ","SAMBAEDU3","",-1,70)
		EndIf

		$MDP_ADMIN_SE3=InputBox("Informations supplémentaires","Mot de passe administrateur SE3: ","","*",-1,60)

		;$LECTEUR="P"
		;$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\admin " & $MDP_ADMIN_SE3 & " /persistent:no & pause")
		$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\admin " & $MDP_ADMIN_SE3 & " /persistent:no")
		If $run_acces_se3 == 0 Or $TEST_netlogon <> "" Then
			$netlogon=$LECTEUR & ":"
		Else
			MsgBox(4096,"ERREUR","Il n'a pas été non plus possible de monter un lecteur " & $LECTEUR & ": pointant sur \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "ABANDON !")
			Exit
		EndIf
	Else
		$netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogon"
	EndIf
Else
	;$PAUSE_DEBUG=" & pause"
	$PAUSE_DEBUG=""
	If $CmdLine[0] == 0 Then
		$NOTE="On ne tente pas de lire des paramètres"
	Else
		If StringInStr($CmdLine[1],"debug") Then
			$PAUSE_DEBUG=" & pause"
		EndIf
	EndIf

	$cible_netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogon"
	;$cible_netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogonzblouc" ; Pour simuler/forcer l'echec de l'acces sans lecteur
	$run=RunWait(@ComSpec & " /c net use " & $cible_netlogon, @SW_SHOW)
	;MsgBox(0,"Info","La tentative d'accès à " & $cible_netlogon & " a retourné " & $run)
	; Le test n'est pas fiable
	;If $run <> 0 Then
	If FileExists($cible_netlogon & "\domscripts\se3.cmd") Then
		$netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogon"
	Else
		;$run=RunWait(@ComSpec & " /c net use Z: " & $cible_netlogon & $PAUSE_DEBUG, @SW_SHOW)
		; On force le démontage/remontage pour éviter des blagues avec plusieurs connexions au même partage ou sous plusieurs identités
		$run=RunWait(@ComSpec & " /c net use " & $cible_netlogon & " /DELETE /Y & net use Z: " & $cible_netlogon & $PAUSE_DEBUG, @SW_SHOW)
		;MsgBox(0,"Info","La tentative d'accès à " & $cible_netlogon & " a retourné " & $run)
		; Le test n'est pas fiable
		;If $run <> 0 Then
		;If Not FileExists($cible_netlogon & "\domscripts\se3.cmd") Then
		If Not FileExists("z:\domscripts\se3.cmd") Then
			; Le montage a échoué

			;SplashTextOn("ERREUR","Il n'a pas été possible d'accéder à \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "Vous avez bien fourni le couple (admin;motdepasse) pour accéder à \\" & $SE3_NETBIOS_NAME & "\Progs\install\domscripts, n'est-ce pas ?",500,100,-1,0)
			SplashTextOn("ERREUR","Il n'a pas été possible d'accéder à \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "Vous avez bien fourni le couple (adminse3;motdepasse) pour accéder à \\" & $SE3_NETBIOS_NAME & "\netlogon\domscripts, n'est-ce pas ?",500,100,-1,0)
			Sleep(4000)
			SplashTextOn("Nouvelle tentative","Nouvelle tentative en montant un lecteur réseau.",500,100,-1,0)
			Sleep(2000)

			;$LECTEUR=_chercher_lecteur_libre()
			$LECTEUR="Z"

			; On teste si NETLOGON est monté (cela pourrait gêner si c'était ailleurs qu'en Z:)
			$TEST_netlogon=_chercher_lecteur_reseau("NETLOGON")
			If $TEST_netlogon <> "" Then
				$LECTEUR=$TEST_netlogon
				$menage=RunWait(@Comspec & " /c net use " & $LECTEUR & ": /delete /y")
			EndIf

			;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			; Il faut réclamer le nom de domaine et le mot de passe admin
			;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			If $DOMAINE == "" Then
				$DOMAINE=InputBox("Informations supplémentaires","Nom de domaine: ","SAMBAEDU3","",-1,70)
			EndIf

			;$MDP_ADMIN_SE3=InputBox("Informations supplémentaires","Mot de passe administrateur SE3: ","","*",-1,60)
			$MDP_ADMINSE3=InputBox("Informations supplémentaires","Mot de passe du compte adminse3: ","","*",-1,60)

			;$LECTEUR="P"
			;$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\admin " & $MDP_ADMIN_SE3 & " /persistent:no")
			;$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\adminse3 " & $MDP_ADMINSE3 & " /persistent:no & pause")
			; On force le démontage/remontage pour éviter des blagues avec plusieurs connexions au même partage ou sous plusieurs identités
			$run_acces_se3=RunWait(@Comspec & " /c net use \\" & $SE3_NETBIOS_NAME & "\netlogon /DELETE /Y & net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\adminse3 " & $MDP_ADMINSE3 & " /persistent:no " & $PAUSE_DEBUG)
			If $run_acces_se3 == 0 Or $TEST_netlogon <> "" Then
				$netlogon=$LECTEUR & ":"
			Else
				MsgBox(4096,"ERREUR","Il n'a pas été non plus possible de monter un lecteur " & $LECTEUR & ": pointant sur \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "ABANDON !")
				Exit
			EndIf
		Else
			$netlogon="Z:"
		EndIf
	EndIf
EndIf

SplashTextOn("Information","Copie des fichiers " & $netlogon & "\domscripts\*.* vers " & $SystemDrive & "\netinst\",500,100,-1,0)
Sleep(2000)
$COPIE=FileCopy($netlogon & "\domscripts\*.*", $SystemDrive & "\netinst\", 1)
If $COPIE = 0 Then
	MsgBox(48,"ERREUR","Echec de la copie des fichiers de " & $netlogon & "\domscripts\ vers " & $SystemDrive & "\netinst\")
	Exit
EndIf

SplashTextOn("Information","Copie de " & $netlogon & "\CPAU.exe vers " & $SystemDrive & "\netinst\",500,100,-1,0)
Sleep(2000)
;copy /y \\%netbios_name%\netlogon\CPAU.exe %Systemdrive%\Netinst\
$COPIE=FileCopy($netlogon & "\CPAU.exe", $SystemDrive & "\netinst\", 1)
If $COPIE = 0 Then
	MsgBox(48,"ERREUR","Echec de la copie de " & $netlogon & "\CPAU.exe vers " & $SystemDrive & "\netinst\")
	Exit
EndIf


If FileExists($netlogon & "\machine\" & $IP & "\action.bat") Then
	SplashTextOn("Information","Copie de " & $netlogon & "\machine\" & $IP & "\action.bat vers " & $SystemDrive & "\netinst\",500,100,-1,0)
	Sleep(1000)
	FileCopy($netlogon & "\machine\" & $IP & "\action.bat", $SystemDrive & "\netinst\", 1)
Else
	SplashTextOn("Information","Recherche ou saisie du nom de machine...",500,100,-1,0)
	Sleep(1000)

	; Nom de la station
	$NAME=""

	;for /f "delims==- tokens=2-7" %%a in ('nbtstat -a %computername% ^|find "Adresse MAC"')  do @set mac=%%a%%b%%c%%d%%e%%f
	$MAC=_GetMACFromIP($IP)
	$MAC_ELAGUEE=StringRegExpReplace($MAC,"[^A-Za-z0-9]","")
    ;:: recuperation du nom de la machine
	If FileExists($SystemDrive & "\netinst\unattend.csv") Then

		;if not exist %systemdrive%\netinst\unattend.csv goto nounattend
		;for /f "tokens=3 delims=," %%a in ('findstr %mac% %systemdrive%\netinst\unattend.csv') do set NAME=%%~a

		$FICH=FileOpen($SystemDrive & "\netinst\unattend.csv",0)
		If $FICH = -1 Then
			; Le fichier n'existe pas ou on n'a pas pu l'ouvrir
			MsgBox(0,"Information", "Le fichier " & $SystemDrive & "\netinst\unattend.csv n'existe pas, ou n'a pas pu être ouvert.", 2)
		Else
			While 1
				$LIGNE=FileReadLine($FICH)
				If @error = -1 Then ExitLoop
				If StringRight(StringLeft($LIGNE,13),12) = $MAC_ELAGUEE Then
					$TEMP=StringSplit($LIGNE,"""")
					$NAME=$TEMP[6]
					ExitLoop
				EndIf
			WEnd
			FileClose($FICH)
		EndIf
	EndIf

	If $NAME == "" Then
		SplashTextOn("Information","Aucune correspondance n'a été trouvée dans le fichier unattend.csv" & @CRLF & "Il vous est proposé d'utiliser le nom actuel de la machine: " & @ComputerName,500,100,-1,0)
		$NAME=@ComputerName
	Else
		If StringLower($NAME) == StringLower(@ComputerName) Then
			SplashTextOn("Information","Le nom de machine " & $NAME & " a été trouvé dans le fichier unattend.csv" & @CRLF & "C'est aussi le nom actuel de la machine.",500,100,-1,0)
		Else
			SplashTextOn("Information","Le nom de machine " & $NAME & " a été trouvé dans le fichier unattend.csv" & @CRLF & "alors que le nom actuel de la machine est " & @ComputerName,500,100,-1,0)
		EndIf
	EndIf
	Sleep(3000)

	While 1
		$NAME=InputBox("Nom de machine", "Veuillez saisir le nom de machine souhaité: ", $NAME, "", -1, 5)
		If @error = 1 Then
			; On a cliqué sur Cancel
			MsgBox(16,"ABANDON","Vous n'avez pas souhaité poursuivre.",1)
			Exit
		EndIf
		If $NAME = "" Then
			MsgBox(48,"ERREUR","Le nom de machine ne doit pas être vide.")
		Else
			$NAME_CORRIGE=StringRegExpReplace($NAME,"[^A-Za-z0-9_-]","")
			If $NAME = $NAME_CORRIGE Then
				$RETOUR=MsgBox(0,"Information","La machine va être mise au domaine sous le nom " & $NAME, 2)
				; La fenêtre se referme toute seule après 2 secondes...
				; On ne peut pas tester $RETOUR == 1
				; Si rien n'a été cliqué, c'est que c'est OK.
				If $RETOUR = 2 Then
					; On a cliqué sur Cancel
					MsgBox(16,"ABANDON","Vous n'avez pas souhaité poursuivre.",1)
					Exit
				Else
					ExitLoop
				EndIf
			Else
				If $NAME_CORRIGE = "" Then
					; On repart dans la boucle
					MsgBox(48,"Information","Des caractères invalides ont été saisis." & @CRLF & "Veuillez-vous limiter à [A-Za-z0-9_-]",3)
					;$NAME=""
				Else
					$RETOUR=MsgBox(4,"Information","Des caractères invalides ont été saisis." & @CRLF & "Le nom proposé est " & $NAME_CORRIGE & @CRLF & "Acceptez-vous ce nom? (sinon préférez-vous corriger)?")
					If $RETOUR = 6 Then
						$NAME=$NAME_CORRIGE
						ExitLoop
					;Else
						;$NAME=""
						;If $RETOUR = 2 Then
						;	MsgBox(16,"ABANDON","Vous n'avez pas souhaité poursuivre.",1)
						;	Exit
						;EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		; A FAIRE: Il faudrait aussi contrôler si le nom est déjà dans unattend.csv
	WEnd

	; Ca ne devrait pas arriver, mais deux précautions valent mieux qu'une
	If $NAME = "" Then
		MsgBox(16,"ERREUR","Le nom de machine est vide." & @CRLF & "On ne peut pas poursuivre")
		Exit
	EndIf

    ;:nounattend
    ;If "$NAME" = "" Then
    ;    cls
	;set /P NAME=entrez le nom de la machine :

	;echo la machine va etre mise au domaine sous le nom %NAME%
    ;echo set ACTION=renomme> %SystemDrive%\Netinst\action.bat
    ;echo set NAME=%NAME%>> %SystemDrive%\Netinst\action.bat
	$FICH=FileOpen($SystemDrive & "\netinst\action.bat",2)
	If $FICH = -1 Then
		MsgBox(16,"ERREUR", "Il n'a pas été possible de créer le fichier " & $SystemDrive & "\netinst\action.bat")
		Exit
	EndIf

	FileWriteLine($FICH,"set ACTION=renomme" & @CRLF)
	FileWriteLine($FICH,"set NAME=" & $NAME & @CRLF)
	FileClose($FICH)
EndIf

$temoin_demander_pass_admin="y"
If FileExists($netlogon & "\machine\" & $IP & "\localpw.job") Then
	$COPIE=FileCopy($netlogon & "\machine\" & $IP & "\localpw.job", $SystemDrive & "\netinst\", 1)
	If $COPIE = 0 Then
		MsgBox(48,"ERREUR","Echec de la copie de " & $netlogon & "\machine\" & $IP & "\localpw.job vers " & $SystemDrive & "\netinst\" & @CRLF & "Vous allez être invité à donner le mot de passe du compte administrateur local.")
	Else
		$temoin_demander_pass_admin="n"
	EndIf
EndIf


_Message("Lancement du programme rejointSE3-elevated.exe sur architecture " & @OSArch & " et sur OS " & @OSVersion & ".")

If @OSArch = "X86" Then
    Switch @OSVersion
        Case "WIN_XP"
            RunWait($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin, $SystemDrive & "\Netinst")
        Case "WIN_7"
            _Execute_elevated($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin)
        Case "WIN_VISTA"
            _Execute_elevated($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin)
        ; etc
        Case Else
            MsgBox(0,"", "OS non référencé : tentative SANS élévation de privilège.")
            RunWait($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin, $SystemDrive & "\Netinst")
    EndSwitch
Else  ; ( x64 )
    Switch @OSVersion
        Case "WIN_XP"
            RunWait($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin, $SystemDrive & "\Netinst")
        Case "WIN_7"
            _Execute_elevated($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin)
        Case "WIN_VISTA"
            _Execute_elevated($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin)
        Case Else
            MsgBox(0,"", "OS non référencé : tentative AVEC élévation de privilège.")
            _Execute_elevated($SystemDrive & "\Netinst\rejointSE3-elevated.exe " & $temoin_demander_pass_admin)
   EndSwitch
EndIf

; FIN DU SCRIPT : toutes les autres commandes ont été copiées dans rejointSE3-elevated.au3 puis compilées


Func _Execute_elevated($script)
    RunWait("cscript " & $SystemDrive & "\Netinst\execute-elevated.js " & $script , $SystemDrive & "\Netinst")
EndFunc

Func _Message($mess)
    SplashTextOn("Information", $mess ,500,100,-1,0)
    Sleep(1000)
EndFunc

