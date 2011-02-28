:: lance le shutdown si busoin
%SystemRoot%\system32\shutdown.exe -r -t 20  -c "redemarrage GPO"
echo startup GPO  OK > %SystemDrive%\netinst\domscripts.txt
