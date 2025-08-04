$logPath = "$env:SystemDrive\setup-log.txt"
Start-Transcript -Path $logPath -Append -UseMinimalHeader
# Set ut time and location
Write-Host 'Setting up location...'
Set-TimeZone -Id 'W. Europe Standard Time'
Set-Culture -CultureInfo 'sv-SE'
Write-Host 'Finished setting up location.'

# Install PowerShell 7
Write-Host 'Installing Powershell 7...'
Invoke-WebRequest -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.msi' -OutFile "$env:TEMP\pwsh.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\pwsh.msi /quiet"
# Remove-Item -Path "$env:TEMP\pwsh.msi" -Force
Write-Host 'Finished installing Powershell 7.'

# Install VS Code
Write-Host 'Installing vscode...'
Invoke-WebRequest -Uri 'https://aka.ms/win32-x64-system-stable' -OutFile "$env:TEMP\vscode.exe"
Start-Process "$env:TEMP\vscode.exe" -Wait -ArgumentList "/VERYSILENT /SP- /SUPPRESSMSGBOXES /NORESTART /NOCANCEL /mergetasks=!runcode"
# Remove-Item -Path "$env:TEMP\vscode.exe" -Force
Write-Host 'Finished installing vscode.'

# Install git
Write-Host 'Installing git...'
Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe' -OutFile "$env:TEMP\git.exe"
Start-Process "$env:TEMP\git.exe" -Wait -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL"
# Remove-Item -Path "$env:TEMP\git.exe" -Force
Write-Host 'Finished installing git.'

# Install go
Write-Host "Installing go..."
Invoke-WebRequest -Uri 'https://go.dev/dl/go1.24.5.windows-amd64.msi' -OutFile "$env:TEMP\go.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\go.msi /quiet"
# Remove-Item -Path "$env:TEMP\go.msi" -Force
Write-Host 'Finished installing go.'

# Install Oh-My-Posh
Write-Host 'Installing oh-my-posh...'
Invoke-WebRequest -Uri '' -OutFile "$env:TEMP\ohmyposh.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\ohmyposh.msi /quiet"
Start-Process "oh-my-posh" -Wait -ArgumentList 'font install meslo'
# Remove-Item -Path "$env:TEMP\ohmyposh.msi" -Force
Write-Host 'Finished installing oh-my-posh.'

# Install mobules
Write-Host 'Installing psmodule posh-git...'
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name 'posh-git' -Force
Write-Host 'Finished installing psmodule posh-git.'

# Add custom PowerShell profile
Write-Host 'Creating Powershell profile...'
New-Item -Path $PROFILE -ItemType File -Force
@'
Import-Module posh-git
oh-my-posh init pwsh --config 'aliens' | Invoke-Expression
'@ | Out-File -FilePath $PROFILE-Encoding utf8 -Force
Write-Host 'Finished creating Powershell profile.'

# Set the font for Powershell in Terminal app
Write-Host 'Setting up Terminal.app...'
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
Write-Host 'Finishing setting up Terminal.app.'

Stop-Transcript