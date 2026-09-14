#!/usr/bin/env bash
# ==============================================================================
# dotfiles installer — jacedeno
# Sets up zsh + Oh My Posh (atomic) + plugins + fzf and symlinks the dotfiles.
# Idempotent: safe to re-run. Existing files are backed up, never overwritten.
# Supports Fedora (dnf) and Debian/Ubuntu (apt). macOS support was dropped on
# 2026-09-14: there is no Mac in the fleet.
# ==============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;32m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dotfiles]\033[0m %s\n' "$*"; }

# --- 1. Packages --------------------------------------------------------------
log "Installing packages..."
# The Nerd Font comes from nerdfonts.com and isn't managed here.
if command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y zsh git curl fzf unzip tree ranger
elif command -v apt >/dev/null 2>&1; then
  sudo apt update && sudo apt install -y zsh git curl fzf unzip tree ranger
else
  warn "No dnf/apt found — install zsh, git, curl, fzf, unzip, tree, ranger manually."
fi

# --- 2. Oh My Posh --------------------------------------------------------------
if ! command -v oh-my-posh >/dev/null 2>&1; then
  log "Installing Oh My Posh to ~/.local/bin..."
  mkdir -p "$HOME/.local/bin"
  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
else
  log "Oh My Posh already installed."
fi

# Pin the atomic theme locally so the prompt works offline (vendored in the repo)
mkdir -p "$HOME/.config/ohmyposh"
cp -f "$DOTFILES/ohmyposh/atomic.omp.json" "$HOME/.config/ohmyposh/atomic.omp.json"

# --- 3. Zsh plugins ---------------------------------------------------------------
mkdir -p "$HOME/.zsh/plugins"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ ! -d "$HOME/.zsh/plugins/$plugin" ]; then
    log "Cloning $plugin..."
    git clone --depth 1 "https://github.com/zsh-users/$plugin" "$HOME/.zsh/plugins/$plugin"
  else
    log "$plugin already present."
  fi
done

# --- 4. Symlink dotfiles ------------------------------------------------------------
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    log "OK: $dst"
    return
  fi
  if [ -e "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    warn "Backed up existing $(basename "$dst") to $BACKUP_DIR"
  fi
  ln -s "$src" "$dst"
  log "Linked: $dst -> $src"
}

link "$DOTFILES/zsh/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES/git/.gitconfig"    "$HOME/.gitconfig"
link "$DOTFILES/git/hooks"         "$HOME/.config/git/hooks"
chmod +x "$DOTFILES/git/hooks/"*
link "$DOTFILES/ranger/rc.conf"    "$HOME/.config/ranger/rc.conf"
if command -v alacritty >/dev/null 2>&1; then
  link "$DOTFILES/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
fi
if command -v systemctl >/dev/null 2>&1; then
  # GUI-launched apps (GNOME app grid, dbus activation) go through the systemd
  # --user manager, not a login shell, so they never see ~/.zshrc's PATH.
  # Needed for anything in ~/.local/bin launched that way (e.g. Alacritty's
  # terminal.shell = herdr). Takes effect on next login, not immediately.
  link "$DOTFILES/environment.d/10-local-bin.conf" "$HOME/.config/environment.d/10-local-bin.conf"
fi
link "$DOTFILES/bin/clip2forge" "$HOME/.local/bin/clip2forge"
chmod +x "$DOTFILES/bin/clip2forge"
link "$DOTFILES/bin/mount-excemca" "$HOME/.local/bin/mount-excemca"
chmod +x "$DOTFILES/bin/mount-excemca"
link "$DOTFILES/bin/herdr-update" "$HOME/.local/bin/herdr-update"
chmod +x "$DOTFILES/bin/herdr-update"

# --- 5. History file -----------------------------------------------------------------
touch "$HOME/.zsh_history" && chmod 600 "$HOME/.zsh_history"

# --- 6. Machine-local overrides -------------------------------------------------------
if [ ! -f "$HOME/.zshrc.local" ]; then
  cat > "$HOME/.zshrc.local" <<'EOF'
# Machine-specific zsh config (not tracked by dotfiles).
# PATH additions, nvm, platformio, work aliases, etc. go here.
EOF
  log "Created ~/.zshrc.local for machine-specific config."
fi

# --- 7. Default shell -------------------------------------------------------------------
if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
  warn "Default shell is not zsh. Change it with: chsh -s $(command -v zsh)"
fi

log "Done. Open a new terminal or run: exec zsh"
