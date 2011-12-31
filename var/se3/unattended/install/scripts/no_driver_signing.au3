#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.2.12.1
 Author:         Lacroix Olivier

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

Run("control sysdm.cpl")
$WinTitle="Propri�t�s syst�me"
$begin = TimerInit()
$tag=0
$tag2=0
If WinWait($WinTitle, "", 600) Then
  ; Boucle au plus 120 sec
  While ( ( (TimerDiff($begin) / 1000) < 60 ) )
	
	; entr�e dans le menu
	If ( ( WinExists("Propri�t�s syst�me") ) and ($tag < 1 ) ) Then
		ControlSend("Propri�t�s syst�me", "",12320,"{RIGHT}")
		Sleep(300)
		controlsend("Propri�t�s syst�me", "",12320,"{RIGHT}")
		Sleep(300)
		ControlClick("Propri�t�s syst�me", "Signat&ure du pilote", "Button4")
		Sleep(300)
		$tag=2
	EndIf
	If ( ( WinExists("Options de signature du pilote") ) and ($tag2 < 1 ) ) Then
		ControlClick("Options de signature du pilote", "&Ignorer�- Forcer l'installation du logiciel sans demander mon approbation", "Button1")
		;ControlClick("Options de signature du pilote", "A&vertir�- Me demander de choisir une action chaque fois", "Button2")
		Sleep(300)
		ControlClick("Options de signature du pilote", "OK", "Button5")
		Sleep(300)
		ControlClick("Propri�t�s syst�me", "OK", "Button8")
		exit 0
		;$tag2=1
	EndIf
	
	Sleep(500)
	WEnd
EndIf


