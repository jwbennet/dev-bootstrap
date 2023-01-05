# Description: Boxstarter script for bootstrapping my developer workstation

# choco install -y chezmoi
# RefreshEnv

# chezmoi init --apply --force jwbennet

$config = Get-Content "$HOME/.dev-machine.json" | ConvertFrom-Json

if($null -ne $config.wslDistributions -And $config.wslDistributions.length -gt 0)
{
  Write-Host "Installing WSL if necessary"
  # choco install -y Microsoft-Windows-Subsystem-Linux -source windowsfeatures
  # choco install -y VirtualMachinePlatform -source windowsfeatures
  # choco install wsl2 --params "/Version:2 /Retry:true"
  # wsl --set-default-version 2

  Write-Host "Setting up WSL distributions"
  $configuredDistributions = @()
  foreach ($wslDistribution in $config.wslDistributions) {
    $source = $wslDistribution.source
    $name = If($wslDistribution.name) { $wslDistribution.name } Else { $source }
    $configuredDistributions += $name
    # Check to see if the named WSL distribution exsists. If not, create it.
    $installedDistributions=wsl --list --quiet
    if ( -not ($installedDistributions -contains $name)) {
        Write-Host "    Setting up $($name) from $($source)"
        # wsl --install --distribution $source
        # # Prompt user to give the source installation time to occur
        # Read-Host "Press ENTER after WSL initialization"
        
        if($name -ne $source) {
          Write-Host "        Renaming $source distribution to $name"
          # wsl --export $source "$env:TEMP\$source.tar.gz"
          # wsl --import $name "$env:TEMP\wsl-dev" "$env:TEMP\$source.tar.gz"
          Write-Host "        Unregistering the $source source distribution"
          # wsl --unregister Ubuntu
        }

        if($wslDistribution.default) {
          Write-Host "        Setting $name as the default WSL distribution"
          # wsl --set-default dev
        }
    } else {
        Write-Host "    There is already a $name WSL distribution so skipping its configuration"
    }

  }
}
