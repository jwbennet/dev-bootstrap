# Description: Boxstarter script for bootstrapping my developer workstation

Disable-UAC
$Boxstarter.AutoLogin=$false

choco install -y chezmoi

Enable-UAC
#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
