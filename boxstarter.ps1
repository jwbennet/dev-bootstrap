# Description: Boxstarter script for bootstrapping my developer workstation

Enable-RemoteDesktop
# Update-ExecutionPolicy Unrestricted

choco install -y chezmoi Boxstarter
RefreshEnv

chezmoi init --apply jwbennet

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

function installWinGetPackage
{
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
installWinGetPackage Balena.Etcher
installWinGetPackage Docker.DockerDesktop
installWinGetPackage GIMP.GIMP
installWinGetPackage Git.Git
installWinGetPackage GitHub.GitHubDesktop
installWinGetPackage Google.Chrome
installWinGetPackage Iterate.Cyberduck
installWinGetPackage JetBrains.IntelliJIDEA.Ultimate
installWinGetPackage Microsoft.Office
installWinGetPackage Microsoft.OneDrive
installWinGetPackage Microsoft.PowerToys
installWinGetPackage Microsoft.VisualStudioCode
installWinGetPackage Microsoft.WindowsTerminal
installWinGetPackage Mozilla.Firefox
installWinGetPackage Notepad++.Notepad++
installWinGetPackage picpick.picpick
installWinGetPackage Postman.Postman
installWinGetPackage SlackTechnologies.Slack
installWinGetPackage Spotify.Spotify
installWinGetPackage Zoom.Zoom
installWinGetPackage Yubico.YubikeyManager

function createShortcut
{
    Param ([string]$Source, [string]$Target)
    if (Test-Path $Target)
    {
        Write-Host "Shortcut for $Target already exists"
    }
    else
    {
        Write-Host "Setting up shortcut for $Source"
        $WScriptObj = New-Object -ComObject ("WScript.Shell")
        $Shortcut = $WscriptObj.CreateShortcut($Target)
        $Shortcut.TargetPath = $Source
        $Shortcut.save()
    }
}

# Create Windows shortcuts
createShortcut -Source "${env:ProgramFiles(x86)}\JetBrains\IntelliJ IDEA 2022.3\bin\idea64.exe" -Target "$HOME\intellij.lnk"
createShortcut -Source "$env:LocalAppData\Programs\GIMP 2\bin\gimp-2.10.exe" -Target "$HOME\gimp.lnk"
createShortcut -Source "$env:ProgramFiles\Notepad++\notepad++.exe" -Target "$HOME\npp.lnk"
createShortcut -Source "$env:LocalAppData\Programs\Microsoft VS Code\Code.exe" -Target "$HOME\vsc.lnk"


# Set Windows Preferences
## Show hidden files, Show protected OS files, Show file extensions
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions

## will expand explorer to the actual folder you're in
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
## adds things back in your left pane like recycle bin
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1
## opens PC to This PC, not quick access
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarMn -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarDa -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
