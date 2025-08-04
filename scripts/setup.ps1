function Write-Log {
  param (
    [Parameter(Mandatory,Position=0)]
    [string]$text,
    [Parameter]
    [string]$path = "$env:SystemDrive\setup-log.txt" 
  )
  Add-Content -Value $text -Path $path
}

function Invoke-FileDownload {
  param (
    [Parameter(Mandatory)]
    [string]$Uri,
    [Parameter(Mandatory)]
    [string]$OutFile,
    [Parameter]
    [int]$TimeoutSeconds = 30,
    [Parameter]
    [int]$MaxRetries = 3
  )
  
  $client = New-Object System.Net.Http.HttpClient
  $client.Timeout = [timespan]::FromSeconds($TimeoutSeconds)
  $attempt = 0
  $success = $false

  while (-not $success -and $attempt -lt $MaxRetries) {
    try {
      $attempt++
      Write-Log "Attempt $($attempt): Downloading: $Uri"
      $response = $client.GetAsync($Uri).Result
      if ($response.IsSuccessStatusCode) {
        [System.IO.File]::WriteAllBytes($OutFile, $response.Content.ReadAsByteArrayAsync())
        $success = $true
      } else {
        Write-Log "Failed to download $($Uri). Status: $($response.StatusCode)"
      }
    }
    catch {
      Write-Log "Error downloading $($Uri): $_"
    }
  }
  if (-not $success) {
    Write-Log "Failed to download $($Uri) after $($MaxRetries) attempts."
  }
  $client.Dispose()
}

Write-Log 'Setting Progress preference...'
$ProgressPreference = 'SilentlyContinue'
Write-Log 'Finished setting Progress preference.'

# Set ut time and location
Write-Log 'Setting up location...'
Set-TimeZone -Id 'W. Europe Standard Time'
Set-Culture -CultureInfo 'sv-SE'
Write-Log 'Finished setting up location.'

# Install PowerShell 7
Write-Log 'Installing Powershell 7...'
Invoke-FileDownload -Uri 'https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.msi' -OutFile "$env:TEMP\pwsh.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\pwsh.msi /quiet"
# Remove-Item -Path "$env:TEMP\pwsh.msi" -Force
Write-Log 'Finished installing Powershell 7.'

# Install VS Code
Write-Log 'Installing vscode...'
Invoke-FileDownload -Uri 'https://aka.ms/win32-x64-system-stable' -OutFile "$env:TEMP\vscode.exe"
Start-Process "$env:TEMP\vscode.exe" -Wait -ArgumentList "/VERYSILENT /SP- /SUPPRESSMSGBOXES /NORESTART /NOCANCEL /mergetasks=!runcode"
# Remove-Item -Path "$env:TEMP\vscode.exe" -Force
Write-Log 'Finished installing vscode.'

# Install git
Write-Log 'Installing git...'
Invoke-FileDownload -Uri 'https://github.com/git-for-windows/git/releases/download/v2.50.1.windows.1/Git-2.50.1-64-bit.exe' -OutFile "$env:TEMP\git.exe" 
Start-Process "$env:TEMP\git.exe" -Wait -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL"
# Remove-Item -Path "$env:TEMP\git.exe" -Force
Write-Log 'Finished installing git.'

# Install go
Write-Log "Installing go..."
Invoke-FileDownload -Uri 'https://go.dev/dl/go1.24.5.windows-amd64.msi' -OutFile "$env:TEMP\go.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\go.msi /quiet"
# Remove-Item -Path "$env:TEMP\go.msi" -Force
Write-Log 'Finished installing go.'

# Install Oh-My-Posh
Write-Log 'Installing oh-my-posh...'
Invoke-FileDownload -Uri 'https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/install-x64.msi' -OutFile "$env:TEMP\ohmyposh.msi"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\ohmyposh.msi /quiet"
Start-Process "oh-my-posh" -Wait -ArgumentList 'font install meslo'
# Remove-Item -Path "$env:TEMP\ohmyposh.msi" -Force
Write-Log 'Finished installing oh-my-posh.'

# Install mobules
Write-Log 'Installing psmodule posh-git...'
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name 'posh-git' -Force
Write-Log 'Finished installing psmodule posh-git.'

# Add custom PowerShell profile
Write-Log 'Creating Powershell profile...'
New-Item -Path $PROFILE -ItemType File -Force
@'
Import-Module posh-git
oh-my-posh init pwsh --config 'aliens' | Invoke-Expression
'@ | Out-File -FilePath $PROFILE-Encoding utf8 -Force
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
