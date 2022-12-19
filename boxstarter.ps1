# Description: Boxstarter script for bootstrapping my developer workstation

Enable-RemoteDesktop

choco install -y chezmoi

# This step accepts the Microsoft Store agreement so we can install packages from there
winget list --accept-source-agreements --accept-package-agreements

# Windows Sub-system for Linux
## Download the Linux kernel update package
choco install -y Microsoft-Windows-Subsystem-Linux -source windowsfeatures
choco install -y VirtualMachinePlatform -source windowsfeatures
wsl --set-default-version 2
choco install wsl2 --params "/Version:2 /Retry:true"
wsl --install --distribution Ubuntu
wsl --export Ubuntu "$env:TEMP\ubuntu.tar.gz"
wsl --import dev "$env:TEMP\wsl-dev" "$env:TEMP\ubuntu.tar.gz"
wsl --set-default dev
wsl --unregister Ubuntu
wsl useradd -m -G sudo -s /bin/bash "jwbennet"

# Install Applications
winget install -e --id 7zip.7zip
winget install -e --id Docker.DockerDesktop
winget install -e --id GitHub.GitHubDesktop
winget install -e --id Google.Chrome
winget install -e --id Postman.Postman
winget install -e --id Microsoft.WindowsTerminal

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
