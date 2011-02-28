' D'après le script rejoin_se3_XP.vbs de:
' Sandrine Dangreville matice creteil
' Il s'agit de rejoindre un groupe de travail 'tmpse3'
' $Id:$

'Option Explicit
Dim oWsh 'Windows Script Host Shell object

Set oWsh = CreateObject("WScript.Shell")
Set oWshEnvironment = oWsh.Environment("Process")
Set oWshnet= Wscript.CreateObject("WScript.Network")

strPassword = WScript.Arguments.Named("p")
strUser = WScript.Arguments.Named("u")
WScript.Echo "Utilisateur: " & strUser


Set objNetwork = CreateObject("WScript.Network")
strComputer = objNetwork.ComputerName
WScript.Echo "Ordinateur: " & strComputer

Set objComputer = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\" & strComputer & "\root\cimv2:Win32_ComputerSystem.Name='" & strComputer & "'")
strDomain = objComputer.Domain
WScript.Echo "Domaine: " & strDomain
intunjoin = objComputer.UnjoinDomainOrWorkgroup(strPassword, strDomain & "\" & strUser, 0)
ReturnValue = objComputer.JoinDomainOrWorkGroup("tmpse3", NULL, NULL, NULL, 0)

WScript.Echo "code : " & ReturnValue
wscript.Quit(ReturnValue mod 255)
