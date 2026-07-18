# ==============================================================================
# PowerShell profile — jacedeno dotfiles (light, native-Windows side)
# The primary shell on Windows is WSL, which runs the same zsh + aliases as the
# Linux machines. This profile is only for native PowerShell tasks: same prompt,
# a few convenience shortcuts. Installed by install.ps1 (dot-sourced from $PROFILE).
# ==============================================================================

# 1. Prompt (Oh My Posh with Atomic theme — matches the zsh prompt)
oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json | Invoke-Expression

# 2. Key Plugins (Prediction & Completion)
# This simulates zsh-autosuggestions
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# 3. Aliases (matching the zsh environment where it makes sense on Windows)
Set-Alias -Name ll -Value ls
function update { winget upgrade --all }          # same name as the zsh 'update' alias

# DevOps Jump commands
function repos { Set-Location ~/repos }
function gpush { git push origin main }
function gpull { git pull origin main }

# Kubernetes & Docker (Shortcuts)
function k { kubectl $args }
function kgp { kubectl get pods $args }
function dps { docker ps $args }

# 4. Utilities
function zconf { notepad $PROFILE }
function zreload { . $PROFILE }