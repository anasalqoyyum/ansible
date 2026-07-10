# In a way, I don't know how to properly document this file. It's a PowerShell profile file that I use to configure my PowerShell environment. 
# It's a mix of things that I've found useful over time. 
# Other things installed: mise, starship, PowerToys CommandNotFound module, Chocolatey, scoop, btop, gh, neofetch, wslcompact, raycast, neovim
# neovim need (uv tool install --upgrade pynvim) -> https://github.com/neovim/neovim/blob/master/INSTALL.md#windows
# scoop install -k ripgrep fd fzf 7zip neovim extras/vcredist2022 gh btop mise starship komorebi zoxide

$ENV:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
$ENV:STARSHIP_LOG = "error"
$ENV:KOMOREBI_CONFIG_HOME = "$HOME\.config\komorebi"
$ENV:WHKD_CONFIG_HOME = "$HOME\.config\komorebi"
# Prevent mise warning on pwsh v5
$env:MISE_PWSH_CHPWD_WARNING=0

function vim { nvim @args }
function lg { lazygit @args }
function gl { git pull @args }

#f45873b3-b655-43a6-b217-97c00aa0db58 PowerToys CommandNotFound module
# Import-Module -Name Microsoft.WinGet.CommandNotFound
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

# Run starship prompt if the terminal supports it
if ($env:TERM -ne 'dumb' -and $Host.UI.SupportsVirtualTerminal) {
    Invoke-Expression (&starship init powershell)
}
Invoke-Expression (& { (zoxide init powershell | Out-String) })
mise activate pwsh | Out-String | Invoke-Expression
