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
  $LCID = 1053       # Swedish LCID
  $LocaleHex = '00000c1d' # sv-SE hex for registry

  Write-Output "Setting system-wide culture to $Culture..."

  # 1. Set system locale (non-Unicode programs)
  Set-WinSystemLocale -SystemLocale $Culture

  # 2. Install and set language for current user
  $LangList = New-WinUserLanguageList $Culture
  Set-WinUserLanguageList $LangList -Force

  # 3. Set culture for current session
  Set-Culture -CultureInfo $Culture

  # 4. Set default input method (keyboard) for current user
  Set-WinUILanguageOverride -Language $Culture
  Set-WinUserLanguageList $LangList -Force

  # 5. Update default user profile for future users
  $DefaultUserReg = 'HKU\.DEFAULT\Control Panel\International'
  $Props = @{
    Locale          = $LocaleHex
    iCountry        = 46          # Sweden
    sShortDate      = 'yyyy-MM-dd'
    sLongDate       = 'yyyy MMMM d'
    sTimeFormat     = 'HH:mm:ss'
    iFirstDayOfWeek = 1        # Monday
    sDecimal        = ','
    sThousand       = ' '
    sCurrency       = 'kr'
  }

  foreach ($Name in $Props.Keys) {
    Set-ItemProperty -Path $DefaultUserReg -Name $Name -Value $Props[$Name]
  }

  # 6. Optional: Set language for welcome screen (OOBE) and system accounts
  # Requires Windows 10/11 Pro or Enterprise
  $MUIRegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\MUI\UILanguages'
  if (-not (Test-Path "$MUIRegPath\$Culture")) {
    New-Item -Path $MUIRegPath -Name $Culture -Force
  }

  # 7. Inform user
  Write-Output "System-wide culture for $Culture set. Reboot required for all changes to take effect."


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
# --- Create PowerShell profile for Default User ---
Write-Output "Creating PowerShell profile for Default User..."

$DefaultProfileDir = "C:\Users\Default\Documents\PowerShell"
$DefaultProfile = Join-Path $DefaultProfileDir "Microsoft.PowerShell_profile.ps1"

if (-not (Test-Path $DefaultProfileDir)) {
    New-Item -Path $DefaultProfileDir -ItemType Directory -Force
}

@"
Import-Module posh-git
oh-my-posh init pwsh --config 'aliens' | Invoke-Expression
"@ | Out-File -FilePath $DefaultProfile -Encoding utf8 -Force

Write-Output "Default PowerShell profile created."

# --- Update Windows Terminal settings for Default User ---
Write-Output "Updating Windows Terminal settings for Default User..."

$DefaultWTPath = "C:\Users\Default\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$DefaultWTSettings = Join-Path $DefaultWTPath "settings.json"

if (-not (Test-Path $DefaultWTPath)) {
    New-Item -Path $DefaultWTPath -ItemType Directory -Force
}

# If settings.json doesn't exist, create a basic template
if (-not (Test-Path $DefaultWTSettings)) {
    @"
{
  ""profiles"": {
    ""list"": []
  }
}
"@ | Out-File -FilePath $DefaultWTSettings -Encoding utf8
}

$settings = Get-Content $DefaultWTSettings -Raw | ConvertFrom-Json

# Update all PowerShell profiles in Windows Terminal
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

# Save changes
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $DefaultWTSettings -Encoding utf8

Write-Output "Windows Terminal default settings updated."

# --- Optional: Copy profile to all existing users ---
$users = Get-ChildItem 'C:\Users' -Directory | Where-Object { $_.Name -notin @('Default', 'Public') }
foreach ($user in $users) {
    $userProfileDir = Join-Path $user.FullName 'Documents\PowerShell'
    if (-not (Test-Path $userProfileDir)) { New-Item -Path $userProfileDir -ItemType Directory -Force }
    Copy-Item -Path $DefaultProfile -Destination (Join-Path $userProfileDir "Microsoft.PowerShell_profile.ps1") -Force

    $userWTPath = Join-Path $user.FullName "AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    if (-not (Test-Path $userWTPath)) { New-Item -Path $userWTPath -ItemType Directory -Force }
    Copy-Item -Path $DefaultWTSettings -Destination (Join-Path $userWTPath "settings.json") -Force
}

Write-Output "Finished applying PowerShell and Windows Terminal defaults for all users."
