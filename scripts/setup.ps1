# Install PowerShell 7
Invoke-WebRequest -Uri https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi -OutFile "$env:TEMP\pwsh.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\pwsh.msi /quiet"

# Install VS Code
Invoke-WebRequest -Uri https://aka.ms/win32-x64-user-stable -OutFile "$env:TEMP\vscode.exe"
Start-Process "$env:TEMP\vscode.exe" -Wait -ArgumentList "/silent"

# Install Oh-My-Posh
Install-Module oh-my-posh -Scope AllUsers -Force

# Add custom PowerShell profile
$profilePath = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
@'
Import-Module oh-my-posh
Set-PoshPrompt -Theme jandedobbeleer
'@ | Out-File -FilePath $profilePath -Encoding utf8 -Force
