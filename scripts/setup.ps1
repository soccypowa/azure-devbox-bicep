function Write-Log {
  param (
    [Parameter(Mandatory, Position = 0)]
    [string]$text,
    [Parameter()]
    [string]$Path = "$env:SystemDrive\setup-log.txt"
  )
  Add-Content -Value $text -Path $path
}

Write-Log 'Setting Progress preference...'
$ProgressPreference = 'SilentlyContinue'
Write-Log 'Finished setting Progress preference.'

# Set ut time and location
Write-Log 'Setting up location...'
try {
  Set-TimeZone -Id 'W. Europe Standard Time'
  Write-Log 'Successfully set timezone to W. Europe Standard Time'
} catch {
  Write-Log "Failed to set timezone: $_"
}

# Set culture persistently system-wide via registry
try {
  $Culture = 'sv-SE'
  $LCID = 1053       # LCID for sv-SE
  $LocaleHex = '00000c1d'

  # 1. Set system locale
  Set-WinSystemLocale -SystemLocale $Culture
  Set-WinUserLanguageList -LanguageList $Culture -Force

  # 2. Set default input and UI languages for all users
  Set-Culture -CultureInfo $Culture

  # 3. Update default profile for new users
  $DefaultUserReg = 'HKU\.DEFAULT\Control Panel\International'
  $props = @{
    Locale      = $LocaleHex
    sShortDate  = 'yyyy-MM-dd'
    sLongDate   = 'yyyy MMMM d'
    sTimeFormat = 'HH:mm:ss'
    iCountry    = 46  # Sweden
  }

  foreach ($name in $props.Keys) {
    Set-ItemProperty -Path $DefaultUserReg -Name $name -Value $props[$name]
  }

  Write-Output "System-wide culture set to $Culture. A reboot may be required."
  Write-Log 'Successfully set culture to sv-SE system-wide'
} catch {
  Write-Log "Failed to set culture: $_"
}
Write-Log 'Finished setting up location.'

# Set up ssh and set key
Write-Log "Setting up SSH"
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
New-Item -Path C:\ProgramData\ssh\administrators_authorized_keys -ItemType File -Force
Set-Service sshd -StartupType Automatic -Status running
# Add-Content -Value "`n" -Path C:\ProgramData\ssh\administrators_authorized_keys
Write-Log "Finished setting up SSH"

# Install Chcolatey
Write-Log "Setting up Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
Write-Log "Finished setup Chocolatey"

# Install PowerShell 7
Write-Log 'Installing Powershell 7...'
choco install powershell-core -y
Write-Log 'Finished installing Powershell 7.'

# Install VS Code
Write-Log 'Installing vscode...'
choco install vscode -y
Write-Log 'Finished installing vscode.'

# Install git
Write-Log 'Installing git...'
choco install git -y
Write-Log 'Finished installing git.'

# Install go
Write-Log "Installing go..."
choco install go -y
Write-Log 'Finished installing go.'

# Install Oh-My-Posh
Write-Log 'Installing oh-my-posh...'
choco install oh-my-posh -y
Start-Process "oh-my-posh" -Wait -ArgumentList 'font install meslo'
Write-Log 'Finished installing oh-my-posh.'

# Install mobules
Write-Log 'Installing psmodule posh-git...'
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name 'posh-git' -Force
Write-Log 'Finished installing psmodule posh-git.'

# Add custom PowerShell profile
Write-Log 'Creating Powershell profile...'
New-Item -Path $PROFILE -ItemType File -Force
@'
Import-Module posh-git
oh-my-posh init pwsh --config 'aliens' | Invoke-Expression
'@ | Out-File -FilePath $PROFILE -Encoding utf8 -Force
Write-Log 'Finished creating Powershell profile.'

# Set the font for Powershell in Terminal app
Write-Log 'Setting up Terminal.app...'
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
$pwshProfiles = $settings.profiles.list | Where-Object { $_.name -like "*PowerShell*" }
foreach ($pwshProfile in $pwshProfiles) {
  if ($pwshProfile.PSObject.Properties.Name -notcontains "font") {
    $pwshProfile | Add-Member -MemberType NoteProperty -Name font -Value @{}  
  }
  $pwshProfile.font = @{
    face = "MesloLGL Nerd Font Mono"
    size = 10
  }
}
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding utf8
Write-Log 'Finishing setting up Terminal.app.'
