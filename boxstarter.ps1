# Description: Boxstarter script for bootstrapping my developer workstation

# We start by refreshing environment variables in case we needed to install Chocolatey before this execution and need to update the PATH
#RefreshEnv

# Boxstarter options
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

Enable-RemoteDesktop

choco install -y chezmoi

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
winget install -e --id 7zip.7zip --accept-source-agreements --accept-package-agreements
winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
winget install -e --id GitHub.GitHubDesktop --accept-source-agreements --accept-package-agreements
winget install -e --id Google.Chrome --accept-source-agreements --accept-package-agreements
winget install -e --id Postman.Postman --accept-source-agreements --accept-package-agreements
winget install -e --id Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
