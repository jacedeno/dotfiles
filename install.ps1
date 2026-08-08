#Requires -Version 5.1
<#
  dotfiles installer — jacedeno (Windows-native half)
  ============================================================================
  Sets up the Windows-native side of the cross-platform terminal environment:
  installs Git + FiraCode Nerd Font + Oh My Posh and points the PowerShell
  profile at the repo config.

  No terminal emulator is installed: Windows Terminal ships with Windows, and
  the repo's terminal config (Alacritty) is Linux/macOS only.

  The *shell* on Windows is WSL — it runs the exact same zsh + dotfiles as the
  Linux machines. After this script:
      wsl --install -d Debian                 # if WSL isn't set up yet (admin)
      # then, inside WSL:
      git clone https://github.com/jacedeno/dotfiles.git ~/repos/dotfiles
      cd ~/repos/dotfiles && ./install.sh
  Point Windows Terminal's default profile at the WSL distro to land in zsh.

  Idempotent: safe to re-run. Existing files are backed up, never overwritten.
  Run from the repo root:   .\install.ps1
#>

$ErrorActionPreference = 'Stop'
$Dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backup   = Join-Path $HOME (".dotfiles-backup\{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Log  { param($m) Write-Host "[dotfiles] $m" -ForegroundColor Green }
function Warn { param($m) Write-Host "[dotfiles] $m" -ForegroundColor Yellow }

# --- 1. Packages (winget) ------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Warn "winget not found. Install 'App Installer' from the Microsoft Store, then re-run."
  exit 1
}

$packages = @(
  @{ id = 'Git.Git';                 name = 'Git' },
  @{ id = 'JanDeDobbeleer.OhMyPosh'; name = 'Oh My Posh' }
)
foreach ($p in $packages) {
  if (winget list --id $p.id -e 2>$null | Select-String -SimpleMatch $p.id) {
    Log "$($p.name) already installed."
  } else {
    Log "Installing $($p.name)..."
    winget install --id $p.id -e --source winget `
      --accept-package-agreements --accept-source-agreements
  }
}

# --- 2. Nerd Font --------------------------------------------------------------
# oh-my-posh ships a font installer. It needs oh-my-posh on PATH, which a brand-new
# winget install may not expose until a fresh shell.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  Log "Installing FiraCode Nerd Font..."
  oh-my-posh font install FiraCode
} else {
  Warn "oh-my-posh not on PATH yet. Open a new terminal and run: oh-my-posh font install FiraCode"
}

# --- 3. Helper: back up an existing file, then write the new one ---------------
function Place-File {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  if (Test-Path $Path) {
    New-Item -ItemType Directory -Force -Path $Backup | Out-Null
    Move-Item -Force $Path (Join-Path $Backup (Split-Path -Leaf $Path))
    Warn "Backed up existing $(Split-Path -Leaf $Path) to $Backup"
  }
  Set-Content -Path $Path -Value $Content -Encoding UTF8
  Log "Wrote: $Path"
}

# --- 4. PowerShell profile: dot-source the repo profile (always current) --------
# Symlinks on Windows need admin / Developer Mode, so use a one-line loader instead.
$psRepo = Join-Path $Dotfiles 'windows\Microsoft.PowerShell_profile.ps1'
Place-File $PROFILE ". `"$psRepo`""

# --- 5. WSL — the real shell ---------------------------------------------------
if (Get-Command wsl -ErrorAction SilentlyContinue) {
  if ((wsl --list --quiet 2>$null | Where-Object { $_.Trim() })) {
    Log "WSL present. Inside it: clone this repo and run ./install.sh for the zsh setup."
  } else {
    Warn "WSL installed but no distro. Run (admin): wsl --install -d Debian"
    Warn "  then inside WSL: git clone ...dotfiles && cd dotfiles && ./install.sh"
  }
} else {
  Warn "WSL not found. Install it (admin): wsl --install -d Debian"
  Warn "  — that gives you the same zsh + aliases + prompt as the Linux machines."
}

Log "Done. Open a new Windows Terminal tab on the WSL distro for the zsh setup."
