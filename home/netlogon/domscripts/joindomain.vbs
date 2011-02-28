' jonction au domaine compatible seven
' $Id:$
' 
' joindomain.vbs /d:domaine  /p:password
' 
'Option Explicit
Dim oWsh 'Windows Script Host Shell object
Set oWsh = CreateObject("WScript.Shell")
Set oWshEnvironment = oWsh.Environment("Process")
Set oWshnet= Wscript.CreateObject("WScript.Network")
Const JOIN_DOMAIN             = 1
Const ACCT_CREATE             = 2
Const ACCT_DELETE             = 4
Const WIN9X_UPGRADE           = 16
Const DOMAIN_JOIN_IF_JOINED   = 32
Const JOIN_UNSECURE           = 64
Const MACHINE_PASSWORD_PASSED = 128
Const DEFERRED_SPN_SET        = 256
Const INSTALL_INVOCATION      = 262144

Dim strDomain
Dim strUser
Dim strPassword

strDomain = WScript.Arguments.Named("d")
strPassword = WScript.Arguments.Named("p")
strUser = strDomain & "\adminse3"
WScript.Echo "Domaine: " & strDomain
WScript.Echo "Utilisateur: " & strUser
'WScript.Echo "Password: " & strPassword

Set objNetwork = CreateObject("WScript.Network")
strComputer = objNetwork.ComputerName
WScript.Echo "ordinateur: " & strComputer

Set objComputer = GetObject("winmgmts:{impersonationLevel=Impersonate}!\\" & strComputer & "\root\cimv2:Win32_ComputerSystem.Name='" & strComputer & "'")
ReturnValue = objComputer.JoinDomainOrWorkGroup(strDomain, strPassword, strUser, NULL, JOIN_DOMAIN + ACCT_CREATE)

Select Case ReturnValue
Case 0 strErrorDescription = "Success"
Case 5 strErrorDescription = "Access is denied"
Case 87 strErrorDescription = "The parameter is incorrect"
Case 110 strErrorDescription = "The system cannot open the specified object"
Case 1219 strErrorDescription = "ERROR_SESSION_CREDENTIAL_CONFLICT"
Case 1323 strErrorDescription = "Unable to update the password"
Case 1326 strErrorDescription = "Logon failure: unknown username or bad password"
Case 1355 strErrorDescription = "The specified domain either does not exist or could not be contacted"
Case 2224 strErrorDescription = "The account already exists"
Case 2691 strErrorDescription = "The machine is already joined to the domain"
Case 2692 strErrorDescription = "The machine is not currently joined to a domain"
End Select

WScript.Echo "resultat: " & strErrorDescription  & "code : " & ReturnValue
wscript.Quit(ReturnValue mod 255)



