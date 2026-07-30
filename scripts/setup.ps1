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