# In a way, I don't know how to properly document this file. It's a PowerShell profile file that I use to configure my PowerShell environment. 
# It's a mix of things that I've found useful over time. 
# Other things installed: mise, starship, PowerToys CommandNotFound module, Chocolatey, scoop, btop, gh, neofetch, wslcompact

Invoke-Expression (&starship init powershell)
$ENV:STARSHIP_CONFIG = "$HOME\starship.toml"

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
Import-Module -Name Microsoft.WinGet.CommandNotFound
#f45873b3-b655-43a6-b217-97c00aa0db58

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

mise activate pwsh | Out-String | Invoke-Expression
