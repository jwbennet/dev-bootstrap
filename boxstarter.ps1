# Description: Boxstarter script for bootstrapping my developer workstation

Enable-RemoteDesktop
Set-ExecutionPolicy Unrestricted -Force

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

function installWinGetPackage {
    Param ([string]$packageId)
    $packageInstalled=winget list --id $packageId --accept-source-agreements
    if ($?)
    {
        Write-Host "Package id '$packageId' is already installed"
    }
    else
    {
        Write-Host "Installing package '$packageId'"
        winget install --exact --id $packageId --accept-source-agreements --accept-package-agreements
    }
}

# Install Applications
installWinGetPackage 7zip.7zip
installWinGetPackage Docker.DockerDesktop
installWinGetPackage GitHub.GitHubDesktop
installWinGetPackage Google.Chrome
installWinGetPackage Postman.Postman
installWinGetPackage Microsoft.WindowsTerminal

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
