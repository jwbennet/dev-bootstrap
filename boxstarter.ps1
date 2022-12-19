# Description: Boxstarter script for bootstrapping my developer workstation

Enable-RemoteDesktop
Set-ExecutionPolicy Unrestricted

choco install -y chezmoi Boxstarter

# Windows Sub-system for Linux
## Download the Linux kernel update package
choco install -y Microsoft-Windows-Subsystem-Linux -source windowsfeatures
choco install -y VirtualMachinePlatform -source windowsfeatures
choco install wsl2 --params "/Version:2 /Retry:true"

# Check to see if the "dev" WSL distribution exsists. If not, create it.
$wslDistributions=wsl --list --quiet
if ( -not ($wslDistributions -contains "dev"))
{
    wsl --set-default-version 2
    wsl --install --distribution Ubuntu
    # Sleep to give the Ubuntu installation time to occur
    Start-Sleep -Seconds 30
    wsl --export Ubuntu "$env:TEMP\ubuntu.tar.gz"
    wsl --import dev "$env:TEMP\wsl-dev" "$env:TEMP\ubuntu.tar.gz"
    wsl --set-default dev
    wsl --unregister Ubuntu
} else {
    Write-Host "There is already a 'dev' WSL distribution so skipping its configuration."
}

# Ensure the WSL user is created based on the current Windows username
$wslUserExists=wsl id -u "$env:UserName"
if (-not $?)
{
    wsl useradd -m -G sudo -s /bin/bash "$env:UserName"
    wsl /bin/bash -c "echo '$($env:UserName):changeme' | chpasswd"
    wsl passwd -e "$env:UserName"
}
else
{
    Write-Host "The user $env:UserName has already been setup."
}

# Install Applications
winget install -e --id 7zip.7zip --accept-source-agreements --accept-package-agreements
winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
winget install -e --id GitHub.GitHubDesktop --accept-source-agreements --accept-package-agreements
winget install -e --id Google.Chrome --accept-source-agreements --accept-package-agreements
winget install -e --id Postman.Postman --accept-source-agreements --accept-package-agreements
winget install -e --id Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
