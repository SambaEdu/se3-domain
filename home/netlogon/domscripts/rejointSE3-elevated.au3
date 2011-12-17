; Script de mise au domaine manuelle
; $Id: rejointSE3.au3 6022 2010-12-04 13:10:11Z crob $
; Stephane Boireau, d'après le script rejointSE3.cmd de Denis Bonnenfant
; N'est normalement lancé qu'en cas d'adhésion 'un nouveau poste
; ou que la mise au domaine depuis l'interface SE3 a échoué.
; Olivier Lacroix : contient les commandes de rejointSE3.au3 qui doivent être passées en environnement
; avec privilèges élevés. Doit être lancé avec un argument depuis rejointSE3.exe
; Derniere modification: 17/12/2011



;Include constants
#include <GUIConstants.au3>

#include <se3_crob.lib.au3>


;SplashTextOn("Information","Lancement du script",500,100,-1,0)
;Sleep(1000)

; lancé avec un argument pour communiquer le résultat d'un test depuis rejointSE3.au3
; l'argument contient $temoin_demander_pass_admin
If $CmdLine[0] <> 1 Then
	SplashTextOn("Information","rejointSE3-elevated.exe ne doit pas être lancé directement. Utiliser rejointSE3.exe pour la mise au domaine.",500,100,-1,0)
	Sleep(5000)
	Exit(1)
Else
	; le test initialisant $temoin_demander_pass_admin se situe dans rejointSE3.exe car il nécessite un accès réseau.
	SplashTextOn("Information","Argument $temoin_demander_pass_admin pris en compte : " & $CmdLine[1],500,100,-1,0)
	Sleep(1000)
	$temoin_demander_pass_admin=$CmdLine[1]
EndIf

; pour tests
;$temoin_demander_pass_admin = "y"

$SystemDrive=_GetSystemDrive()


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



If $temoin_demander_pass_admin == "y" Then
	$MDP_ADMINISTRATEUR=""
	While $MDP_ADMINISTRATEUR == ""

		$MDP_ADMINISTRATEUR=InputBox("Informations supplémentaires","Pour imposer à Administrateur le mot de passe d'adminse3, valider directement par Entree." & @CRLF & @CRLF & "Si vous souhaitez un mot de passe specifique pour le compte Administrateur, entrez le mot de passe : ","","",-1,200)

		If @error == 1 Then
			MsgBox(0,"Abandon","Vous avez souhaité abandonner l'intégration.")
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

			MsgBox(4096,"ERREUR","Il n'a pas été possible d'accéder à " & @ComputerName & "\C$" & @CRLF & @CRLF & "Soit le mot de passe administrateur est incorrect," & @CRLF & "soit les partages administratifs sont désactivés et cela va perturber l'intégration." & @CRLF & @CRLF & "Contrôlez la clé [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters\AutoShareWks]" & @CRLF & @CRLF & "Sa valeur actuelle a l'air d'être: '" & $AutoShareWks & "'." & @CRLF & "Elle ne doit pas être à '0' pour que les choses se passent bien.")

			;Windows Registry Editor Version 5.00
			;[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters]
			;"AutoShareWks"=dword:00000001

			;Exit
			$MDP_ADMINISTRATEUR=""
		EndIf
	WEnd

	If $MDP_ADMINISTRATEUR == "" Then
		MsgBox(0,"Information","Le mot de passe administrateur sera modifié pour prendre celui de 'adminse3'.")
	Else
		; start /wait %Systemdrive%\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file %Systemdrive%\Netinst\localpw.job  -lwp -c -ex "net user administrateur %LOCALPW%"
		;MsgBox(0,"Info","RunWait(@Comspec & "" /c "" & $SystemDrive & "":\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file "" & $SystemDrive & ""\Netinst\localpw.job  -lwp -c -ex ""net user administrateur " & $MDP_ADMINISTRATEUR & """")
		RunWait(@Comspec & " /c " & $SystemDrive & ":\Netinst\CPAU.exe -u administrateur -p wawa -wait -enc -file " & $SystemDrive & "\Netinst\localpw.job  -lwp -c -ex ""net user administrateur " & $MDP_ADMINISTRATEUR & """")
	EndIf
EndIf


SplashTextOn("Shutdown","Le script shutdown.cmd va être lancé pour achever de préparer l'intégration et rebooter la machine.",-1,70)
Sleep(1000)
RunWait(@ComSpec & " /c " & $SystemDrive & "\Netinst\shutdown.cmd")
