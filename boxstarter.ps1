# Description: Boxstarter script for bootstrapping my developer workstation

Enable-RemoteDesktop
Update-ExecutionPolicy Unrestricted

choco install -y chezmoi Boxstarter git
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
wsl id -u "$env:UserName" | Out-Null
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

# Install Ansible and use it to configure the WSL distribution
wsl -u root -- /bin/bash -c "apt-get update && apt-get upgrade -y && apt-get install -y python3 python-is-python3 python3-pip && python -m pip install --user ansible --no-warn-script-location"
wsl -u "$env:UserName" -- /bin/bash -c 'cd ~ && $(curl -fsLS get.chezmoi.io)'
wsl -u "$env:UserName" -- /bin/bash -c "`$HOME/bin/chezmoi init --apply $env:UserName"
wsl -u "$env:UserName" -- /bin/bash -c "python -m pip install --user ansible --no-warn-script-location"
wsl -u "$env:UserName" -- /bin/bash -c "mkdir -p $HOME/projects && git clone https://github.com/jwbennet/dev-bootstrap.git `$HOME/projects/dev-bootstrap"
wsl -u root -- /bin/bash -c "cd /home/${env:UserName}/projects/dev-bootstrap/ansible && /root/.local/bin/ansible-playbook --extra-vars='wsl_username=jwbennet' main.yaml"
wsl --terminate dev

function installWinGetPackage
{
    Param ([string]$packageId)
    winget list --id $packageId --accept-source-agreements | Out-Null
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
installWinGetPackage NGWIN.PicPick
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

function pinToQuickAccess
{
    Param ([string]$Target)
    $ShellObj = New-Object -ComObject shell.application -Verbose
    $ShellObj.Namespace($Target).Self.InvokeVerb("PinToHome")
}

pinToQuickAccess("$HOME")

# Set Windows Terminal settings if present
if ( Test-Path "$HOME\.wtconfig" )
{
    $wtSettings="$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if ( (Test-Path $wtSettings) -and (Get-Item $wtSettings).LinkType -ne "SymbolicLink" )
    {
        Remove-Item -Path $wtSettings -Force
        New-Item -ItemType SymbolicLink -Path $wtSettings -Target "$HOME\.wtconfig"
    }
}

# Set Windows Preferences
## Set Windows theme
Start-Process -FilePath "$HOME\.windows.theme"
## Show hidden files, Show protected OS files, Show file extensions
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions
## opens PC to This PC, not quick access
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1
## Always expand "Show more options" in Explorer
reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
## Disable Snap Assist
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "EnableSnapAssistFlyout" -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "SnapAssist" -Value 0
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -Value 0


# Disable various unused taskbar features in Windows 11
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarMn -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarDa -Value 0
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0

# Set Time Zone
Set-TimeZone -Id "Eastern Standard Time"

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
