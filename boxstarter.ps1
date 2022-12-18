# Description: Boxstarter script for bootstrapping my developer workstation

Enable-RemoteDesktop

choco install -y chezmoi

# This step accepts the Microsoft Store agreement so we can install packages from there
winget list --accept-source-agreements --accept-package-agreements

winget install -e --id 7zip.7zip
winget install -e --id Docker.DockerDesktop
winget install -e --id GitHub.GitHubDesktop
winget install -e --id Google.Chrome
winget install -e --id Postman.Postman
winget install -e --id Microsoft.WindowsTerminal

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
