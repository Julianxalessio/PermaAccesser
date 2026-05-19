powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://gyan.dev' -OutFile '%temp%\ffmpeg.zip'"
powershell -NoProfile -Command "Expand-Archive -Path '%temp%\ffmpeg.zip' -DestinationPath '%temp%\ffmpeg_extracted' -Force"
powershell -NoProfile -Command "Move-Item (Get-ChildItem -Path '%temp%\ffmpeg_extracted' -Recurber -Filter 'ffmpeg.exe').FullName -Destination 'C:\Windows\System32\' -Force"
powershell -NoProfile -Command "Remove-Item '%temp%\ffmpeg.zip', '%temp%\ffmpeg_extracted' -Recurse -Force"
ffmpeg -version
