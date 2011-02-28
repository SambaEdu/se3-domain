; Script de mise au domaine manuelle
; $Id$
; Stephane Boireau, d'apr�s le script rejointSE3.cmd de Denis Bonnenfant
; N'est normalement lanc� qu'en cas d'adh�sion 'un nouveau poste 
; ou que la mise au domaine depuis l'interface SE3 a �chou�.
; Derniere modification: 04/12/2010

;Include constants
#include <GUIConstants.au3>

#include <se3_crob.lib.au3>

; Recuperation des parametres dans le m�me dossier
$SE3_IP=IniRead(@ScriptDir & "\se3ip.ini", "ParamSE3", "se3ip", "")
$SE3_NETBIOS_NAME=IniRead(@ScriptDir & "\se3ip.ini", "ParamSE3", "netbios_name", "")
$DOMAINE=IniRead(@ScriptDir & "\se3ip.ini", "ParamSE3", "se3_domain", "")
;MsgBox(0,"Info","DOMAINE=" & $DOMAINE)
;Exit

If $SE3_IP = "" Then
	MsgBox(0,"ERREUR", "La variable $SE3_IP est vide." & @CRLF & "Le fichier " & @ScriptDir & "\se3ip.ini est-il renseign�?")
	Exit
EndIf

If $SE3_NETBIOS_NAME = "" Then
	MsgBox(0,"ERREUR", "La variable $SE3_NETBIOS_NAME est vide." & @CRLF & "Le fichier " & @ScriptDir & "\se3ip.ini est-il renseign�?")
	Exit
EndIf

$IP=_GetIP()
If $IP = "" Then
	MsgBox(0,"ERREUR", "L'adresse IP du poste n'a pas �t� trouv�e.")
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
	;MsgBox(0,"Info","La tentative d'acc�s � " & $cible_netlogon & " a retourn� " & $run)
	; Le test n'est pas fiable
	;If $run <> 0 Then
	If Not FileExists($cible_netlogon & "\domscripts\se3.cmd") Then

		SplashTextOn("ERREUR","Il n'a pas �t� possible d'acc�der � \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "Vous avez bien fourni le couple (admin;motdepasse) pour acc�der � \\" & $SE3_NETBIOS_NAME & "\Progs\install\domscripts, n'est-ce pas ?",500,100,-1,0)
		Sleep(4000)
		SplashTextOn("Nouvelle tentative","Nouvelle tentative en montant un lecteur r�seau.",500,100,-1,0)
		Sleep(2000)

		$LECTEUR=_chercher_lecteur_libre()
		
		$TEST_netlogon=_chercher_lecteur_reseau("NETLOGON")
		If $TEST_netlogon <> "" Then 
			$LECTEUR=$TEST_netlogon
			$menage=RunWait(@Comspec & " /c net use " & $LECTEUR & ": /delete /y")
		EndIf
		
		;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		; Il faut r�clamer le nom de domaine et le mot de passe admin
		;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		If $DOMAINE == "" Then
			$DOMAINE=InputBox("Informations suppl�mentaires","Nom de domaine: ","SAMBAEDU3","",-1,70)
		EndIf
		
		$MDP_ADMIN_SE3=InputBox("Informations suppl�mentaires","Mot de passe administrateur SE3: ","","*",-1,60)

		;$LECTEUR="P"
		;$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\admin " & $MDP_ADMIN_SE3 & " /persistent:no & pause")
		$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\admin " & $MDP_ADMIN_SE3 & " /persistent:no")
		If $run_acces_se3 == 0 Or $TEST_netlogon <> "" Then
			$netlogon=$LECTEUR & ":"
		Else
			MsgBox(4096,"ERREUR","Il n'a pas �t� non plus possible de monter un lecteur " & $LECTEUR & ": pointant sur \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "ABANDON !")
			Exit
		EndIf
	Else
		$netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogon"
	EndIf
Else
	;$PAUSE_DEBUG=" & pause"
	$PAUSE_DEBUG=""
	If $CmdLine[0] == 0 Then
		$NOTE="On ne tente pas de lire des param�tres"
	Else
		If StringInStr($CmdLine[1],"debug") Then
			$PAUSE_DEBUG=" & pause"
		EndIf
	EndIf
	
	$cible_netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogon"
	;$cible_netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogonzblouc" ; Pour simuler/forcer l'echec de l'acces sans lecteur
	$run=RunWait(@ComSpec & " /c net use " & $cible_netlogon, @SW_SHOW)
	;MsgBox(0,"Info","La tentative d'acc�s � " & $cible_netlogon & " a retourn� " & $run)
	; Le test n'est pas fiable
	;If $run <> 0 Then
	If FileExists($cible_netlogon & "\domscripts\se3.cmd") Then
		$netlogon="\\" & $SE3_NETBIOS_NAME & "\netlogon"
	Else
		;$run=RunWait(@ComSpec & " /c net use Z: " & $cible_netlogon & $PAUSE_DEBUG, @SW_SHOW)
		; On force le d�montage/remontage pour �viter des blagues avec plusieurs connexions au m�me partage ou sous plusieurs identit�s
		$run=RunWait(@ComSpec & " /c net use " & $cible_netlogon & " /DELETE /Y & net use Z: " & $cible_netlogon & $PAUSE_DEBUG, @SW_SHOW)
		;MsgBox(0,"Info","La tentative d'acc�s � " & $cible_netlogon & " a retourn� " & $run)
		; Le test n'est pas fiable
		;If $run <> 0 Then
		;If Not FileExists($cible_netlogon & "\domscripts\se3.cmd") Then
		If Not FileExists("z:\domscripts\se3.cmd") Then
			; Le montage a �chou�

			;SplashTextOn("ERREUR","Il n'a pas �t� possible d'acc�der � \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "Vous avez bien fourni le couple (admin;motdepasse) pour acc�der � \\" & $SE3_NETBIOS_NAME & "\Progs\install\domscripts, n'est-ce pas ?",500,100,-1,0)
			SplashTextOn("ERREUR","Il n'a pas �t� possible d'acc�der � \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "Vous avez bien fourni le couple (adminse3;motdepasse) pour acc�der � \\" & $SE3_NETBIOS_NAME & "\netlogon\domscripts, n'est-ce pas ?",500,100,-1,0)
			Sleep(4000)
			SplashTextOn("Nouvelle tentative","Nouvelle tentative en montant un lecteur r�seau.",500,100,-1,0)
			Sleep(2000)

			;$LECTEUR=_chercher_lecteur_libre()
			$LECTEUR="Z"
			
			; On teste si NETLOGON est mont� (cela pourrait g�ner si c'�tait ailleurs qu'en Z:)
			$TEST_netlogon=_chercher_lecteur_reseau("NETLOGON")
			If $TEST_netlogon <> "" Then 
				$LECTEUR=$TEST_netlogon
				$menage=RunWait(@Comspec & " /c net use " & $LECTEUR & ": /delete /y")
			EndIf
			
			;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			; Il faut r�clamer le nom de domaine et le mot de passe admin
			;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			If $DOMAINE == "" Then
				$DOMAINE=InputBox("Informations suppl�mentaires","Nom de domaine: ","SAMBAEDU3","",-1,70)
			EndIf
			
			;$MDP_ADMIN_SE3=InputBox("Informations suppl�mentaires","Mot de passe administrateur SE3: ","","*",-1,60)
			$MDP_ADMINSE3=InputBox("Informations suppl�mentaires","Mot de passe du compte adminse3: ","","*",-1,60)

			;$LECTEUR="P"
			;$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\admin " & $MDP_ADMIN_SE3 & " /persistent:no")
			;$run_acces_se3=RunWait(@Comspec & " /c net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\adminse3 " & $MDP_ADMINSE3 & " /persistent:no & pause")
			; On force le d�montage/remontage pour �viter des blagues avec plusieurs connexions au m�me partage ou sous plusieurs identit�s
			$run_acces_se3=RunWait(@Comspec & " /c net use \\" & $SE3_NETBIOS_NAME & "\netlogon /DELETE /Y & net use " & $LECTEUR & ": \\" & $SE3_NETBIOS_NAME & "\netlogon /user:" & $DOMAINE & "\adminse3 " & $MDP_ADMINSE3 & " /persistent:no " & $PAUSE_DEBUG)
			If $run_acces_se3 == 0 Or $TEST_netlogon <> "" Then
				$netlogon=$LECTEUR & ":"
			Else
				MsgBox(4096,"ERREUR","Il n'a pas �t� non plus possible de monter un lecteur " & $LECTEUR & ": pointant sur \\" & $SE3_NETBIOS_NAME & "\netlogon" & @CRLF & "ABANDON !")
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

;if exist \\%netbios_name%\netlogon\machine\%IP%\action.bat goto action
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
			MsgBox(0,"Information", "Le fichier " & $SystemDrive & "\netinst\unattend.csv n'existe pas, ou n'a pas pu �tre ouvert.", 2)
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
		SplashTextOn("Information","Aucune correspondance n'a �t� trouv�e dans le fichier unattend.csv" & @CRLF & "Il vous est propos� d'utiliser le nom actuel de la machine: " & @ComputerName,500,100,-1,0)
		$NAME=@ComputerName
	Else
		If StringLower($NAME) == StringLower(@ComputerName) Then
			SplashTextOn("Information","Le nom de machine " & $NAME & " a �t� trouv� dans le fichier unattend.csv" & @CRLF & "C'est aussi le nom actuel de la machine.",500,100,-1,0)		
		Else
			SplashTextOn("Information","Le nom de machine " & $NAME & " a �t� trouv� dans le fichier unattend.csv" & @CRLF & "alors que le nom actuel de la machine est " & @ComputerName,500,100,-1,0)
		EndIf
	EndIf
	Sleep(3000)

	While 1
		$NAME=InputBox("Nom de machine", "Veuillez saisir le nom de machine souhait�: ", $NAME, "", -1, 5)
		If @error = 1 Then
			; On a cliqu� sur Cancel
			MsgBox(16,"ABANDON","Vous n'avez pas souhait� poursuivre.",1)
			Exit
		EndIf
		If $NAME = "" Then
			MsgBox(48,"ERREUR","Le nom de machine ne doit pas �tre vide.")
		Else
			$NAME_CORRIGE=StringRegExpReplace($NAME,"[^A-Za-z0-9_-]","")
			If $NAME = $NAME_CORRIGE Then
				$RETOUR=MsgBox(0,"Information","La machine va �tre mise au domaine sous le nom " & $NAME, 2)
				; La fen�tre se referme toute seule apr�s 2 secondes... 
				; On ne peut pas tester $RETOUR == 1 
				; Si rien n'a �t� cliqu�, c'est que c'est OK.
				If $RETOUR = 2 Then
					; On a cliqu� sur Cancel
					MsgBox(16,"ABANDON","Vous n'avez pas souhait� poursuivre.",1)
					Exit
				Else
					ExitLoop
				EndIf
			Else
				If $NAME_CORRIGE = "" Then
					; On repart dans la boucle
					MsgBox(48,"Information","Des caract�res invalides ont �t� saisis." & @CRLF & "Veuillez-vous limiter � [A-Za-z0-9_-]",3)
					;$NAME=""
				Else
					$RETOUR=MsgBox(4,"Information","Des caract�res invalides ont �t� saisis." & @CRLF & "Le nom propos� est " & $NAME_CORRIGE & @CRLF & "Acceptez-vous ce nom? (sinon pr�f�rez-vous corriger)?")
					If $RETOUR = 6 Then
						$NAME=$NAME_CORRIGE
						ExitLoop
					;Else
						;$NAME=""
						;If $RETOUR = 2 Then
						;	MsgBox(16,"ABANDON","Vous n'avez pas souhait� poursuivre.",1)
						;	Exit
						;EndIf
					EndIf
				EndIf
			EndIf
		EndIf
		; A FAIRE: Il faudrait aussi contr�ler si le nom est d�j� dans unattend.csv
	WEnd
	
	; Ca ne devrait pas arriver, mais deux pr�cautions valent mieux qu'une
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
		MsgBox(16,"ERREUR", "Il n'a pas �t� possible de cr�er le fichier " & $SystemDrive & "\netinst\action.bat")
		Exit
	EndIf
	
	FileWriteLine($FICH,"set ACTION=renomme" & @CRLF)
	FileWriteLine($FICH,"set NAME=" & $NAME & @CRLF)
	FileClose($FICH)
EndIf

;	if exist z:\machine\%IP%\localpw.job (
;		copy /y z:\machine\%IP%\action.bat %systemdrive%\netinst
;	)
;	else (
;		:passwd
;		cls
;		set /P LOCALPW=entrez le mot de passe adminstrateur :
;		if "%LOCALPW%x" == "x" goto shutdown
;		net use \\%computername%\c$ /user:%computername%\administrateur %LOCALPW%
;		if errorlevel 1 goto passwd
;		net use \\%computername%\c$ /delete
;		start /wait %Systemdrive%\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file %Systemdrive%\Netinst\localpw.job  -lwp -c -ex "net user administrateur %LOCALPW%"
;	)

$temoin_demander_pass_admin="y"
If FileExists($netlogon & "\machine\" & $IP & "\localpw.job") Then
	$COPIE=FileCopy($netlogon & "\machine\" & $IP & "\localpw.job", $SystemDrive & "\netinst\", 1)
	If $COPIE = 0 Then
		MsgBox(48,"ERREUR","Echec de la copie de " & $netlogon & "\machine\" & $IP & "\localpw.job vers " & $SystemDrive & "\netinst\" & @CRLF & "Vous allez �tre invit� � donner le mot de passe du compte administrateur local.")
	Else
		$temoin_demander_pass_admin="n"
	EndIf
EndIf

If $temoin_demander_pass_admin == "y" Then
	$MDP_ADMINISTRATEUR=""
	While $MDP_ADMINISTRATEUR == ""

		$MDP_ADMINISTRATEUR=InputBox("Informations suppl�mentaires","Pour imposer � Administrateur le mot de passe d'adminse3, valider directement par Entree." & @CRLF & @CRLF & "Si vous souhaitez un mot de passe specifique pour le compte Administrateur, entrez le mot de passe : ","","",-1,200)

		If @error == 1 Then
			MsgBox(0,"Abandon","Vous avez souhait� abandonner l'int�gration.")
			Exit
		EndIf

		If $MDP_ADMINISTRATEUR == "" Then
			ExitLoop
		EndIf

		$run_acces_xp=RunWait(@Comspec & " /c net use \\" & @ComputerName & "\C$ /user:" & @ComputerName & "\administrateur " & $MDP_ADMINISTRATEUR & " /persistent:no")
	
		If $run_acces_xp == 0 Then
			; Acces OK, le mot de passe est valide
			MsgBox(0,"Information","Le mot de passe est valide",3)
	
			$menage=RunWait(@Comspec & " /c net use \\" & @ComputerName & "\C$ /delete /y")
		Else
			$AutoShareWks=RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters","AutoShareWks")

			MsgBox(4096,"ERREUR","Il n'a pas �t� possible d'acc�der � " & @ComputerName & "\C$" & @CRLF & @CRLF & "Soit le mot de passe administrateur est incorrect," & @CRLF & "soit les partages administratifs sont d�sactiv�s et cela va perturber l'int�gration." & @CRLF & @CRLF & "Contr�lez la cl� [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters\AutoShareWks]" & @CRLF & @CRLF & "Sa valeur actuelle a l'air d'�tre: '" & $AutoShareWks & "'." & @CRLF & "Elle ne doit pas �tre � '0' pour que les choses se passent bien.")

			;Windows Registry Editor Version 5.00
			;[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters]
			;"AutoShareWks"=dword:00000001

			;Exit
			$MDP_ADMINISTRATEUR=""
		EndIf
	WEnd

	If $MDP_ADMINISTRATEUR == "" Then
		MsgBox(0,"Information","Le mot de passe administrateur sera modifi� pour prendre celui de 'adminse3'.")
	Else
		; start /wait %Systemdrive%\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file %Systemdrive%\Netinst\localpw.job  -lwp -c -ex "net user administrateur %LOCALPW%"
		;MsgBox(0,"Info","RunWait(@Comspec & "" /c "" & $SystemDrive & "":\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file "" & $SystemDrive & ""\Netinst\localpw.job  -lwp -c -ex ""net user administrateur " & $MDP_ADMINISTRATEUR & """")
		RunWait(@Comspec & " /c " & $SystemDrive & ":\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file " & $SystemDrive & "\Netinst\localpw.job  -lwp -c -ex ""net user administrateur " & $MDP_ADMINISTRATEUR & """")
	EndIf
EndIf


SplashTextOn("Shutdown","Le script shutdown.cmd va �tre lanc� pour achever de pr�parer l'int�gration et rebooter la machine.",-1,70)
Sleep(1000)
RunWait(@ComSpec & " /c " & $SystemDrive & "\Netinst\shutdown.cmd")
