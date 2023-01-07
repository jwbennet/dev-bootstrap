# Description: Boxstarter script for bootstrapping my developer workstation

$dotfilesRepository = "jwbennet"

Update-ExecutionPolicy Unrestricted

function Create-Shortcut {
  Param ([string]$Source, [string]$Target)
  if (Test-Path $Target) {
      Write-Host "Shortcut for $(Resolve-Path -Path $Target) already exists"
  } else {
      Write-Host "Setting up shortcut for $(Resolve-Path -Path $Source)"
      $WScriptObj = New-Object -ComObject ("WScript.Shell")
      $Shortcut = $WscriptObj.CreateShortcut($Target)
      $Shortcut.TargetPath = $Source
      $Shortcut.save()
  }
}

function Get-RandomPassword {
  param (
      [Parameter(Mandatory)]
      [int] $length,
      [int] $amountOfNonAlphanumeric = 1
  )
  Add-Type -AssemblyName 'System.Web'
  return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}

function Install-WinGetPackage {
    Param ([string]$PackageId, [string]$Source = "winget")
    winget list --id $PackageId --accept-source-agreements | Out-Null
    if ($?)
    {
        Write-Host "Package id '$PackageId' is already installed"
    }
    else
    {
        Write-Host "Installing package '$PackageId'"
        winget install --exact --id $PackageId --source $Source --accept-source-agreements --accept-package-agreements
    }
}

function PinTo-QuickAccess {
    Param ([string]$Target)
    $ShellObj = New-Object -ComObject shell.application -Verbose
    $ShellObj.Namespace($Target).Self.InvokeVerb("PinToHome")
}

Write-Host "Installing and configuring dotfiles from $dotfilesRepository"

choco install -y chezmoi git
RefreshEnv

chezmoi init --apply --force $dotfilesRepository

$config = Get-Content "$HOME/.dev-machine.json" | ConvertFrom-Json

if($null -ne $config.wslDistributions -And $config.wslDistributions.length -gt 0) {
  Write-Host "Installing WSL if necessary"
  choco install -y Microsoft-Windows-Subsystem-Linux -source windowsfeatures
  choco install -y VirtualMachinePlatform -source windowsfeatures
  choco install wsl2 --params "/Version:2 /Retry:true"
  wsl --set-default-version 2

  Write-Host "Setting up WSL distributions"
  foreach ($wslDistribution in $config.wslDistributions) {
    $source = $wslDistribution.source
    $name = If($wslDistribution.name) { $wslDistribution.name } Else { $source }
    # Check to see if the named WSL distribution exsists. If not, create it.
    $installedDistributions=wsl --list --quiet
    if ( -not ($installedDistributions -contains $name)) {
        Write-Host "    Setting up $($name) from $($source)"
        wsl --install --distribution $source
        # Prompt user to give the source installation time to occur
        Read-Host "Press ENTER after WSL initialization"
        
        if($name -ne $source) {
          Write-Host "        Renaming $source distribution to $name"
          wsl --export $source "$env:TEMP\$source.tar.gz"
          wsl --import $name "$env:TEMP\wsl-$name" "$env:TEMP\$source.tar.gz"
          Write-Host "        Unregistering the $source source distribution"
          wsl --unregister $source
        }

        if($wslDistribution.default) {
          Write-Host "        Setting $name as the default WSL distribution"
          wsl --set-default $name
        }
    } else {
        Write-Host "    There is already a $name WSL distribution so skipping its configuration"
    }

    # Ensure the WSL user is created based on the current Windows username
    $wslUsername = If($wslDistribution.username) { $wslDistribution.username } Else { $env:UserName }
    wsl -d $name id -u "$wslUsername" 2>&1 | Out-Null
    if (-not $?) {
        $randomPassword = Get-RandomPassword 12
        wsl -d $name -u root useradd -m -G sudo -s /bin/bash "$wslUsername"
        wsl -d $name -u root /bin/bash -c "echo '$($wslUsername):$randomPassword' | chpasswd"
        wsl -d $name -u root passwd -e "$wslUsername"
        Write-Host "        The user $wslUsername was created with password $randomPassword which should be changed"
    }
    else {
        Write-Host "        The user $username has already been setup."
    }

    # Install Ansible and use it to configure the WSL distribution
    wsl -d $name -u root -- /bin/bash -c "apt-get update && apt-get upgrade -y && apt-get install -y python3 python-is-python3 python3-pip && python -m pip install --user ansible --no-warn-script-location && mkdir -p /projects && chown ${username}.${username} /projects"
    wsl -d $name -u "$username" -- /bin/bash -c 'cd ~ && $(curl -fsLS get.chezmoi.io)'
    wsl -d $name -u "$username" -- /bin/bash -c "`$HOME/bin/chezmoi init --apply --force $dotfilesRepository"
    wsl -d $name -u "$username" -- /bin/bash -c "python -m pip install --user ansible --no-warn-script-location"
    wsl -d $name -u "$username" -- /bin/bash -c "git clone https://github.com/jwbennet/dev-bootstrap.git /projects/dev-bootstrap"
    wsl -d $name -u root -- /bin/bash -c "cd /projects/dev-bootstrap/ansible && /root/.local/bin/ansible-playbook --extra-vars='wsl_username=$username' main.yaml"
    wsl -d $name -u "$username" -- /bin/bash -c "cd /projects/dev-bootstrap/ansible && `$HOME/.local/bin/ansible-playbook user.yaml"
    wsl --terminate $name
  }
}

if($null -ne $config.chocolateyPackages) {
  Write-Host "Installing desired chocolatey packages"
  foreach ($chocolateyPackage in $config.chocolateyPackages) {
    choco install $chocolateyPackage
  }
}

if($null -ne $config.wingetPackages) {
  Write-Host "Installing desired winget packages"
  foreach ($wingetPackage in $config.wingetPackages) {
    Install-WinGetPackage $wingetPackage
  }
}

if($null -ne $config.msStoreApps) {
  Write-Host "Installing desired Microsoft Store apps"
  foreach ($msStoreApp in $config.msStoreApps) {
    $msStoreApp -match "^([^:]*:)?(\w+)$" | Out-Null
    Install-WinGetPackage $Matches.2 "msstore"
  }
}

if($null -ne $config.shortcuts) {
  Write-Host "Configuring shortcuts"
  foreach($shortcut in $config.shortcuts) {
    $source = $ExecutionContext.InvokeCommand.ExpandString($shortcut.source)
    $target = $ExecutionContext.InvokeCommand.ExpandString($shortcut.target)
    Create-Shortcut -Source $source -Target $target
  }
}

if($null -ne $config.quickAccessItems) {
  Write-Host "Configuring quick access items"
  foreach($shortcut in $config.quickAccessItems) {
    $target = $ExecutionContext.InvokeCommand.ExpandString($shortcut)
    PinTo-QuickAccess -Target $target 
  }
}

# Set Windows Terminal settings if present
if(Test-Path "$HOME\.wtconfig") {
  $wtSettings="$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  if( (Test-Path $wtSettings) -and (Get-Item $wtSettings).LinkType -ne "SymbolicLink" ) {
      Remove-Item -Path $wtSettings -Force
      New-Item -ItemType SymbolicLink -Path $wtSettings -Target "$HOME\.wtconfig"
      Write-Host "Updated Windows Terminal Configuration"
  } else {
      Write-Host "Windows Terminal Configuration already in place"
  }
} else {
    Write-Host "Windows Terminal Configuration not found"
}

# Set Windows theme if present
if(Test-Path "$HOME\.windows.theme") {
  Start-Process -FilePath "$HOME\.windows.theme"
  Write-Host "Windows theme set"
} else {
  Write-Host "No Windows theme found"
}

# Set Windows Preferences
if($null -ne $config.windowsPreferences -And $config.windowsPreferences.length -gt 0) {
  Write-Host "Configuring Windows Preferences"
  if($config.windowsPreferences -contains "showHiddenFiles") {
    Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives
    Write-Host "    Hidden files/folders/drives are now shown"
  }
  if($config.windowsPreferences -contains "showFileExtensions") {
    Set-WindowsExplorerOptions -EnableShowFileExtensions
    Write-Host "    File extensions are now shown"
  }
  if($config.windowsPreferences -contains "openToThisPC") {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1
    Write-Host "    Computer will now open directly to drive list"
  }
  if($config.windowsPreferences -contains "alwaysShowRightClickContextMenu") {
    reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null
    Write-Host "    Windows 11 will now always expand the right-click menu"
  }
  if($config.windowsPreferences -contains "disableSnapAssist") {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "EnableSnapAssistFlyout" -Value 0
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "SnapAssist" -Value 0
    Write-Host "    Snap Assist has been disabled"
  }
  if($config.windowsPreferences -contains "disableTaskBarTaskView") {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0
    Write-Host "    Task bar task view button has been disabled"  
  }
  if($config.windowsPreferences -contains "disableTaskBarMessenger") {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarMn -Value 0
    Write-Host "    Task bar messenger has been disabled"
  }
  if($config.windowsPreferences -contains "disableTaskBarWidgets") {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarDa -Value 0
    Write-Host "    Task bar widgets have been disabled"    
  }
  if($config.windowsPreferences -contains "disableTaskBarSearch") {
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0
    Write-Host "    Task bar search has been disabled"
  }
  if($config.windowsPreferences -contains "enableRemoteDesktop") {
    Enable-RemoteDesktop
    Write-Host "    Remote Desktop has been enabled"
  }
}

if($null -ne $config.timezone) {
  Set-TimeZone -Id $config.timezone
  Write-Host "Time zone set to $($config.timezone)"
}

# Configure Windows SSH Agent
if($null -ne $config.sshKeys -And $config.sshKeys.length -gt 0) {
  Write-Host "SSH keys provided so enabling Windows OpenSSH Agent"
  $sshAgentService = Get-Service -Name ssh-agent
  if ($sshAgentService.Status -ne 'Running') {
    Start-Service ssh-agent
    Set-Service ssh-agent -StartupType Automatic
    Write-Host "    Started OpenSSH Agent"
  } else {
    Write-Host "    OpenSSH Agent already running"
  }
  $sshKeyAdded = ssh-add -l
  if($sshKeyAdded -eq "The agent has no identities.") {
    foreach($sshKey in $config.sshKeys) {
      $sshKey = $ExecutionContext.InvokeCommand.ExpandString($sshKey)
      if(Test-Path $sshKey) {
        $sshKey = Resolve-Path -Path $sshKey
        Write-Host "Enter passphrase for ${sshKey}:"
        ssh-add $sshKey
      } else {
        Write-Host "No SSH key found at $sshKey"
      }  
    }
  } else {
    Write-Host "    At least one SSH key already imported so not importing additional keys"
  }
}

#Enable-MicrosoftUpdate
#Install-WindowsUpdate -acceptEula
