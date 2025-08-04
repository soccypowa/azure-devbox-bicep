# Set ut time and location
Set-TimeZone -Id 'W. Europe Standard Time'
Set-Culture -CultureInfo 'sv-SE'

# Install PowerShell 7
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.msi -OutFile "$env:TEMP\pwsh.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\pwsh.msi /quiet"
# Remove-Item -Path "$env:TEMP\pwsh.msi" -Force

# Install VS Code
Invoke-WebRequest -Uri https://aka.ms/win32-x64-user-stable -OutFile "$env:TEMP\vscode.exe"
Start-Process "$env:TEMP\vscode.exe" -Wait -ArgumentList "/VERYSILENT /SP- /SUPPRESSMSGBOXES /NORESTART /NOCANCEL"
# Remove-Item -Path "$env:TEMP\vscode.exe" -Force

# Install mobules
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name 'posh-git' -Force

# Install git
Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe -OutFile "$env:TEMP\git.exe"
Start-Process "$env:TEMP\git.exe" -Wait -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL"
# Remove-Item -Path "$env:TEMP\git.exe" -Force

# Install go
Invoke-WebRequest -Uri https://go.dev/dl/go1.24.5.windows-amd64.msi -OutFile "$env:TEMP\go.msi"
Start-Process "$env:TEMP\go.msi" -Wait -ArgumentList "/q"
# Remove-Item -Path "$env:TEMP\go.msi" -Force

# Install Oh-My-Posh
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
Start-Process "oh-my-posh font install meslo" -Wait
Start-Process "oh-my-posh" -Wait -ArgumentList 'font install meslo'

# Add custom PowerShell profile
New-Item -Path $PROFILE -ItemType File -Force
@'
Import-Module posh-git
oh-my-posh init pwsh --config 'aliens' | Invoke-Expression
'@ | Out-File -FilePath $PROFILE-Encoding utf8 -Force

# Set the font for Powershell in Terminal app
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