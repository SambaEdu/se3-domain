' D'après le script rejoin_se3_XP.vbs de:
' Sandrine Dangreville matice creteil
' Il s'agit de supprimer le compte adminse3
' Stephane Boireau AS Bernay/Pont-Audemer (27)
' 08 juillet 2005

'Option Explicit
Dim oWsh 'Windows Script Host Shell object
Dim sCurrentName 'holds computername environment variable
Dim oWshEnvironment 'Windows Script Host environment object
Dim sAdminName

Set oWsh = CreateObject("WScript.Shell")
Set oWshEnvironment = oWsh.Environment("Process")
Set oWshnet= Wscript.CreateObject("WScript.Network")

sCurrentName= oWshnet.ComputerName

sAdminName="adminse3"

Set ComputerObj = GetObject("WinNT://" & sCurrentName )
'error("Instanciation de l'objet Computer")
ComputerObj.Filter = Array("user")
For Each oUser In ComputerObj
	'MsgBox "compte " & oUser.name ,vbInformation + vbOkOnly + vbApplicationModal + 0,"Installation"
	If LCase(oUser.Name) = LCase(sAdminName) Then
		ComputerObj.Delete "user",sAdminName
		'error( oUser.Name & " already has an account. Destroyed")
		'MsgBox "compte admin détruit " & sAdminName ,vbInformation + vbOkOnly + vbApplicationModal + 0,"Installation"
	End If
Next

' Il serait intéressant de récupérer le nom du dossier HOME d'adminse3
' Comment le faire en VBS?
' Sinon, utiliser aussi un script autoit, avec des cases à cocher pour les dossiers à supprimer.
