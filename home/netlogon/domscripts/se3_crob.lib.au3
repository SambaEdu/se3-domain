; Bibliotheque de fonctions
; $Id: se3_crob.lib.au3 5520 2010-05-14 06:00:36Z crob $
; Stephane Boireau, ex-Animateur de Secteur d'une académie qui croit en l'appropriation des TICE par tous
; Modification: 25/04/2010

;============================================================
; Trouve sur le net: http://www.autoitscript.com/forum/index.php?showtopic=34736
Func _GetMACFromIP($sIP)
    Local $MAC, $MACSize
    Local $i, $s, $r, $iIP
    $MAC = DllStructCreate("byte[6]")
    $MACSize = DllStructCreate("int")
    DllStructSetData($MACSize, 1, 6)
    $r = DllCall("Ws2_32.dll", "int", "inet_addr", "str", $sIP)
    $iIP = $r[0]
    $r = DllCall("iphlpapi.dll", "int", "SendARP", "int", $iIP, "int", 0, "ptr", DllStructGetPtr($MAC), "ptr", DllStructGetPtr($MACSize))
    $s = ""
    For $i = 0 To 5
        If $i Then $s = $s & ":"
        $s = $s & Hex(DllStructGetData($MAC, 1, $i + 1), 2)
    Next
    Return $s
EndFunc
;============================================================
Func _GetIP()
	Dim $tab_ip[4]
	$tab_ip[0]=@IPAddress1
	$tab_ip[1]=@IPAddress2
	$tab_ip[2]=@IPAddress3
	$tab_ip[3]=@IPAddress4

	$return_ip=""

	For $i = 0 to UBound($tab_ip) - 1
		$ip_test=$tab_ip[$i]
		If $ip_test <> "0.0.0.0" Then
			If $ip_test <> "127.0.0.1" Then
				$return_ip=$ip_test
				ExitLoop
			EndIf
		EndIf
	Next

	Return $return_ip
EndFunc
;============================================================
Func _GetValue($nom,$chemin_fichier)
	$valeur=""

	$FICH= FileOpen($chemin_fichier,0)
	If $FICH = -1 Then
		;MsgBox(0, "Erreur", "Il n'a pas été possible d'ouvrir le fichier '" & $chemin_fichier & "'!")
		Exit
	EndIf

	While 1
		$LIGNE = FileReadLine($FICH)
		;MsgBox(0,"Info",$LIGNE)
		If @error = -1 Then ExitLoop
		If StringInStr ($LIGNE,$nom & "=") <> 0 Then
			$LIGNE2_TROUVEE = $LIGNE

			;MsgBox(0,"Info","Ligne trouvée:" & $LIGNE)

			$TEMP=StringSplit($LIGNE, "=")
			$valeur=$TEMP[1]
			ExitLoop
		EndIf
	Wend

	Return $valeur
EndFunc
;============================================================
Func verif_ip($ip)
	; Contrôle des saisies:
	$erreur = "non"
	$ip_sans_point = StringReplace($ip,".","")
	$nombre_de_remplacements = @extended
	If StringIsDigit($ip_sans_point) AND $nombre_de_remplacements == 3  Then
		$octet = StringSplit($ip,".")
		; $octet[0] donne le nombre d'indices du tableau.
		For $i = 1 to 4
			;MsgBox(0,"Info","octet[" & $i & "] = " & $octet[$i])
			If $octet[$i] < 0 OR $octet[$i] > 255 Then
				$erreur = "oui"
				ExitLoop
			EndIf
		Next
	Else
		$erreur = "oui"
	EndIf

	;MsgBox(0,"Info","erreur = " & $erreur)

	If $erreur == "oui" Then
		MsgBox(0, "Erreur", "Un champ contient des caractères non valides" & @CRLF & "ou ne contient pas les 4 octets séparés par des points.")
		return "erreur"
	EndIf
EndFunc
;============================================================
Func _GetSystemDrive()
	$TEMP=StringSplit(@WindowsDir,":")
	;$TEMP[0] contient la dimension du tableau
	;$TEMP[1] contient ce qui précède le premier ':'
	Return $TEMP[1] & ":"
EndFunc
;============================================================
; http://sourceforge.net/projects/winipchanger/
; License: GNU General Public License (GPL)
; A compléter avec les fonctions utiles pour le changement d'IP... dans le cadre du paquet post-clonage

Func _Get_Adapters()
	$objWMIService = ObjGet("winmgmts:\\localhost\root\CIMV2")
	$wbemFlagReturnImmediately = 0x10
	$wbemFlagForwardOnly = 0x20

	$Adapters = ""
	SplashTextOn("Liste des interfaces réseau", "Please Wait...", 170, 40)
	$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter", "WQL", $wbemFlagReturnImmediately + $wbemFlagForwardOnly)
	For	$objItem in $colItems
		If $objItem.NetConnectionID <> "" Then $Adapters = $Adapters & "|" & $objItem.NetConnectionID
	Next
	SplashOff()
	If $Adapters = "" Then $Adapters="Aucune interface reseau n'a ete trouvee."

	; On retourne quelque chose comme "|Connexion au réseau local" ou "|Connexion au réseau local|Connexion au réseau local 2|Connexion réseau sans fil" avec le | en premier caractère.
	Return $Adapters
EndFunc

; Fonction un peu bricolée d'après celle de winipchanger
Func _Set_DHCP($interface)
	$show=@SW_SHOW
	$WinTitle="Changement de l'adressage IP"

	$utiliser_interface_reseau_bat = "n"
	; Ca ne fonctionne pas... il dit que l'interface n'est pas valide... pb d'accents DOS probablement.

	ProgressOn($WinTitle, "Changing IP Address")
	If FileExists(@ScriptDir & "\interface_reseau.bat") And $utiliser_interface_reseau_bat = "y" Then
		$run = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip set address name="%INTERFACE%" source=dhcp & netsh interface ip set address name="%INTERFACE%" source=dhcp', "", $show)
		ProgressSet(20)
		$run3 = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh int ip set dns "%INTERFACE%" dhcp & netsh int ip set dns "%INTERFACE%" dhcp', "", $show)
		ProgressSet(40)
		RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip set wins "%INTERFACE%" dhcp & netsh interface ip set wins "%INTERFACE%" dhcp', "", $show)
		ProgressSet(60)
		RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo ipconfig /release "%INTERFACE%" & ipconfig /release "%INTERFACE%"', "", $show)
		ProgressSet(80)
		$run2 = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo ipconfig /renew "%INTERFACE%" & ipconfig /renew "%INTERFACE%"', "", $show)
	Else
		$run = RunWait(@ComSpec & " /c " & '@echo netsh interface ip set address name="' & $interface & '" source=dhcp & netsh interface ip set address name="' & $interface & '" source=dhcp', "", $show)
		ProgressSet(20)
		$run3 = RunWait(@ComSpec & " /c " & '@echo netsh int ip set dns "' & $interface & '" dhcp & netsh int ip set dns "' & $interface & '" dhcp', "", $show)
		ProgressSet(40)
		RunWait(@ComSpec & " /c " & '@echo netsh interface ip set wins "' & $interface & '" dhcp & netsh interface ip set wins "' & $interface & '" dhcp', "", $show)
		ProgressSet(60)
		RunWait(@ComSpec & " /c " & '@echo ipconfig /release "' & $interface & '" & ipconfig /release "' & $interface & '"', "", $show)
		ProgressSet(80)
		$run2 = RunWait(@ComSpec & " /c " & '@echo ipconfig /renew "' & $interface & '" & ipconfig /renew "' & $interface & '"', "", $show)
	EndIf
	ProgressSet(100)
	Sleep(500)
	ProgressOff()
EndFunc

; Fonction un peu bricolée d'après celle de winipchanger
Func _Set_ip($interface, $IP, $NETMASK, $GW, $DNS, $WINS)
	$show=@SW_SHOW
	$WinTitle="Changement de l'adressage IP"

	; $pause non vide perturbe le test de succès du changement IP
	;$pause=" & pause"
	$pause=""

	$utiliser_interface_reseau_bat = "n"
	; Ca ne fonctionne pas... il dit que l'interface n'est pas valide... pb d'accents DOS probablement.

	ProgressOn($WinTitle, "Changement de l'adresse (IP statique)")
	If FileExists(@ScriptDir & "\interface_reseau.bat") And $utiliser_interface_reseau_bat = "y" Then
		If $GW <> "" Then
			$run = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip set address name="%INTERFACE%" static ' & $IP & " " & $NETMASK & " " & $GW & ' 1 & netsh interface ip set address name="%INTERFACE%" static ' & $IP & " " & $NETMASK & " " & $GW & " 1" & $pause, "", $show)
		Else
			$run = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip set address name="%INTERFACE%" static ' & $IP & " " & $NETMASK & ' & netsh interface ip set address name="%INTERFACE%" static ' & $IP & " " & $NETMASK & $pause, "", $show)
		EndIf
		ProgressSet(50)

		If $DNS <> "" Then
			$rundeldns = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip delete dns "%INTERFACE%" all' & ' & netsh interface ip delete dns "%INTERFACE%" all' & $pause, "", $show)
			If $DNS <> "none" And $DNS <> "aucun" Then
				$rundns = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip set dns name="%INTERFACE%" static ' & $DNS & ' & netsh interface ip set dns name="%INTERFACE%" static ' & $DNS & $pause, "", $show)
			EndIf
		EndIf

		If $WINS <> "" Then
			$rundelwins = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip delete wins "%INTERFACE%" all' & ' & netsh interface ip delete wins "%INTERFACE%" all' & $pause, "", $show)
			If $DNS <> "none" And $DNS <> "aucun" Then
				$runwins = RunWait(@ComSpec & " /c " & 'call ' & @ScriptDir & '\interface_reseau.bat & @echo netsh interface ip set wins name="%INTERFACE%" static ' & $WINS & ' & netsh interface ip set wins name="%INTERFACE%" static ' & $WINS & $pause, "", $show)
			EndIf
		EndIf
	Else
		If $GW <> "" Then
			;$run = RunWait(@ComSpec & " /c " & 'netsh interface ip set address name="' & $interface & '" static ' & $IP & " " & $NETMASK & " " & $GW & " 1", "", $show)
			$run = RunWait(@ComSpec & " /c " & '@echo netsh interface ip set address name="' & $interface & '" static ' & $IP & " " & $NETMASK & " " & $GW & ' 1 & netsh interface ip set address name="' & $interface & '" static ' & $IP & " " & $NETMASK & " " & $GW & " 1" & $pause, "", $show)
		Else
			$run = RunWait(@ComSpec & " /c " & '@echo netsh interface ip set address name="' & $interface & '" static ' & $IP & " " & $NETMASK & ' & netsh interface ip set address name="' & $interface & '" static ' & $IP & " " & $NETMASK & $pause, "", $show)
		EndIf
		ProgressSet(50)

		If $DNS <> "" Then
			$rundeldns = RunWait(@ComSpec & " /c " & '@echo netsh interface ip delete dns "' & $interface & '" all' & ' & netsh interface ip delete dns "' & $interface & '" all' & $pause, "", $show)
			If $DNS <> "none" And $DNS <> "aucun" Then
				;$rundns = RunWait(@ComSpec & " /c " & 'netsh interface ip set dns name="' & $interface & '" static ' & $DNS, "", $show)
				$rundns = RunWait(@ComSpec & " /c " & '@echo netsh interface ip set dns name="' & $interface & '" static ' & $DNS & ' & netsh interface ip set dns name="' & $interface & '" static ' & $DNS & $pause, "", $show)
			EndIf
		EndIf

		If $WINS <> "" Then
			$rundelwins = RunWait(@ComSpec & " /c " & '@echo netsh interface ip delete wins "' & $interface & '" all' & ' & netsh interface ip delete wins "' & $interface & '" all' & $pause, "", $show)
			If $DNS <> "none" And $DNS <> "aucun" Then
				;$runwins = RunWait(@ComSpec & " /c " & 'netsh interface ip set wins name="' & $interface & '" static ' & $WINS, "", $show)
				$runwins = RunWait(@ComSpec & " /c " & '@echo netsh interface ip set wins name="' & $interface & '" static ' & $WINS & ' & netsh interface ip set wins name="' & $interface & '" static ' & $WINS & $pause, "", $show)
			EndIf
		EndIf
	EndIf
	ProgressSet(100)
	Sleep(500)
	ProgressOff()

	If $run = 0 Then
		MsgBox(0,$WinTitle, "L'adresse a été modifiée avec succès.",3)
		Sleep(1000)
	Else
		MsgBox(0,$WinTitle, "Echec du changement d'adresse." & @CRLF & "Veuillez contrôler vos paramètres et cablage.")
	EndIf
EndFunc

;============================================================
Func _lire_unattend_csv($CHEMIN, $MAC)
	; Pour rechercher le NOMPC correspondant à une adresse MAC
	; On lit des lignes du type "000C29BBCF7C","ComputerName","xpbof"

	; Nettoyagge de l'adresse MAC
	$MAC=StringRegExpReplace($MAC,"[^A-Za-z0-9]","")

	$NOMPC=""

	$FICH=FileOpen($CHEMIN,0)
	If $FICH = -1 Then
		;MsgBox(0, "Erreur", "Il n'a pas été possible de créer le fichier!")
	Else
		While 1
			$LIGNE=FileReadLine($FICH)
			If @error = -1 Then ExitLoop
			;MsgBox(0,"Info","LIGNE=" & $LIGNE)
			If StringRegExp(StringLower($LIGNE), "^""" & StringLower($MAC)) Then
				;MsgBox(0,"Info","MAC trouvée : " & $LIGNE)
				$TAB=StringSplit($LIGNE,'"')
				$NOMPC=$TAB[6]
				; On devrait sortir à ce stade par
				;ExitLoop
				; mais, cela complique le traitement d'ajout d'entrées dans le unattend.csv
				; En continuant dans la boucle, c'est le dernier nom ajouté dans le fichier
				; (pour l'adresse MAC) qui est pris en compte.
			EndIf
		WEnd
	EndIf
	FileClose($FICH)

	Return $NOMPC
EndFunc

;$CHEMIN="C:\temp\se3_1.50\domscripts\unattend.csv"
;$MAC="000C29BBCF7C"
;$NOMPC=_lire_unattend_csv($CHEMIN, $MAC)
;MsgBox(0,"Info","MAC=" & $MAC & @CRLF & "NOMPC=" & $NOMPC)

Func _completer_unattend_csv($CHEMIN, $NOMPC, $MAC)
	; Nettoyagge de l'adresse MAC
	$MAC=StringRegExpReplace($MAC,"[^A-Za-z0-9]","")

	;If FileExists($CHEMIN) Then
		$FICH=FileOpen($CHEMIN,1)
		If $FICH = -1 Then
			MsgBox(0, "Erreur", "Il n'a pas été possible d'ouvrir le fichier " & $CHEMIN & " en écriture !")
			Return False
			Exit
		Else
			FileWriteLine($FICH, """" & $MAC & """,""ComputerName"",""" & $NOMPC & """")
			FileWriteLine($FICH, """" & $NOMPC & """,""FullName"",""" & $NOMPC & """")
		EndIf
		FileClose($FICH)
		Return True
	;Else
	;	MsgBox(0, "Erreur", "Le fichier " & $CHEMIN & " n'a pas été trouvé !")
	;EndIf
EndFunc

Func _chercher_lecteur_libre()
	$RETOUR=""

	; En commençant à A, on obtient des erreurs???
	;$alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	$alphabet="CDEFGHIJKLMNOPQRSTUVWXYZ"
	For $i = 1 to StringLen($alphabet)
		$lecteur=StringMid($alphabet,$i,1)
		;MsgBox(0,"Info","lecteur " & $i & "=" & $lecteur)
		;If FileExists($lecteur & ":\NUL") Then
		If Not FileExists($lecteur & ":\") Then
			; Ce n'est ni une partition ni un lecteur réseau

			;MsgBox(0,"Info",$lecteur & ":\ non trouvé")
			; Ca peut encore être un lecteur CD ou disquette vide
			$TEST=RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\" & $lecteur, "BaseClass")
			;MsgBox(0,"Info","lecteur=" & $lecteur & @CRLF & "TEST=" & $TEST & @CRLF & "@error=" & @error)
			If @error <> 0 Then
				; Ce n'est pas non plus un périphérique amovible absent
				$RETOUR=$lecteur
				ExitLoop
			EndIf
		EndIf
	Next

	;A REVOIR: Remplacer par DriveGetDrive()

	Return $RETOUR
EndFunc

;_chercher_lecteur_libre()

Func _chercher_lecteur_reseau($PARTAGE)
	$RETOUR=""

	;$var = DriveGetDrive( "all" )
	$var = DriveGetDrive( "NETWORK" )
	If NOT @error Then
		;MsgBox(4096,"", "Found " & $var[0] & " drives")
		For $i = 1 to $var[0]
			$Label=DriveGetLabel($var[$i])
			;MsgBox(4096,"Drive " & $i, "$var[$i]=" & $var[$i] & @CRLF & "Label=" & $Label)
			If StringLower($Label) == StringLower($PARTAGE) Then
				$RETOUR=StringRegExpReplace($var[$i],"[^A-Za-z]","")
				ExitLoop
			EndIf
		Next
	EndIf

	Return $RETOUR
EndFunc

Func FDEBUG_crob($FICHIER, $TEXTE)
   If $FICHIER == "" Then
      ; On ne fait rien
   Else
       $FICH=FileOpen($FICHIER,1)
       If $FICH = -1 Then
	       ;MsgBox(0, "Erreur", "Il n'a pas été possible d'ouvrir le fichier " & $FICHIER & " en écriture !")
      Else
	       FileWriteLine($FICH, @YEAR & "-" & @MON  & "-" & @MDAY  & " " & @HOUR  & ":" & @MIN  & ":" & @SEC  & " : " &  $TEXTE & @CRLF)
       EndIf
       FileClose($FICH)
   EndIf
EndFunc
