#!/usr/bin/env bash
# ==============================================================================
# dotfiles installer — jacedeno
# Sets up zsh + Oh My Posh (atomic) + plugins + fzf and symlinks the dotfiles.
# Idempotent: safe to re-run. Existing files are backed up, never overwritten.
# Supports Fedora (dnf) and Debian/Ubuntu (apt).
# ==============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;32m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dotfiles]\033[0m %s\n' "$*"; }

# --- 1. Packages --------------------------------------------------------------
log "Installing packages..."
if command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y zsh git curl fzf unzip
elif command -v apt >/dev/null 2>&1; then
  sudo apt update && sudo apt install -y zsh git curl fzf unzip
else
  warn "No dnf/apt found — install zsh, git, curl, fzf manually."
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
if command -v terminator >/dev/null 2>&1; then
  link "$DOTFILES/terminator/config" "$HOME/.config/terminator/config"
fi

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
