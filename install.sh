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
  sudo dnf install -y zsh git curl fzf unzip tree
elif command -v apt >/dev/null 2>&1; then
  sudo apt update && sudo apt install -y zsh git curl fzf unzip tree
else
  warn "No dnf/apt found — install zsh, git, curl, fzf, unzip, tree manually."
fi

# --- 2. Oh My Posh --------------------------------------------------------------
# Check the install path too, not just PATH: a non-interactive shell (ssh host
# ./install.sh) has no ~/.local/bin on PATH, and the bare `command -v` check
# used to re-download the binary on every such run.
if ! command -v oh-my-posh >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/oh-my-posh" ]; then
  log "Installing Oh My Posh to ~/.local/bin..."
  mkdir -p "$HOME/.local/bin"
  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
else
  log "Oh My Posh already installed."
fi

# Pin the atomic theme locally so the prompt works offline (vendored in the repo)
mkdir -p "$HOME/.config/ohmyposh"
cp -f "$DOTFILES/ohmyposh/atomic.omp.json" "$HOME/.config/ohmyposh/atomic.omp.json"

# --- 2b. Yazi -------------------------------------------------------------------
# Terminal file manager (replaced ranger 2026-10-09; see docs/yazi.md). No distro
# packages it, so bin/yazi-update puts the upstream binary in ~/.local/bin.
# update() in .zshrc runs the same script to keep it current.
if ! command -v yazi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/yazi" ]; then
  log "Installing Yazi to ~/.local/bin..."
  "$DOTFILES/bin/yazi-update"
else
  log "Yazi already installed."
fi

# Retire ranger on machines set up before 2026-10-09. Only the package and the
# dangling rc.conf symlink go; ~/.local/share/ranger (bookmarks) is left alone.
if command -v dnf >/dev/null 2>&1 && rpm -q ranger >/dev/null 2>&1; then
  log "Removing ranger (replaced by yazi)..."
  sudo dnf remove -y ranger
elif command -v apt >/dev/null 2>&1 && dpkg -s ranger >/dev/null 2>&1; then
  log "Removing ranger (replaced by yazi)..."
  sudo apt remove -y ranger
fi
if [ -L "$HOME/.config/ranger/rc.conf" ] && [ "$(readlink "$HOME/.config/ranger/rc.conf")" = "$DOTFILES/ranger/rc.conf" ]; then
  rm "$HOME/.config/ranger/rc.conf"
fi
rmdir "$HOME/.config/ranger" 2>/dev/null || true

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
if [ "$(hostname -s)" = geekforge ] && command -v podman >/dev/null 2>&1; then
  # herdr shells have no systemd --user session; see containers/containers.conf.
  link "$DOTFILES/containers/containers.conf" "$HOME/.config/containers/containers.conf"
fi
link "$DOTFILES/bin/clip2forge" "$HOME/.local/bin/clip2forge"
chmod +x "$DOTFILES/bin/clip2forge"
link "$DOTFILES/bin/mount-excemca" "$HOME/.local/bin/mount-excemca"
chmod +x "$DOTFILES/bin/mount-excemca"
link "$DOTFILES/bin/herdr-update" "$HOME/.local/bin/herdr-update"
chmod +x "$DOTFILES/bin/herdr-update"
link "$DOTFILES/bin/yazi-update" "$HOME/.local/bin/yazi-update"
chmod +x "$DOTFILES/bin/yazi-update"

# --- 4a. herdr: yazi launcher -------------------------------------------------------
# Where herdr runs, add the herdr-yazi plugin and its keys: ctrl+b y opens yazi in
# a split in the current pane's folder, ctrl+b Y in a new tab. herdr's config.toml
# is per machine (themes, sound), so only this block is appended, once, marked by
# the plugin's action id. Needs yazi installed first: the plugin's build checks it.
herdr_bin="$(command -v herdr || echo "$HOME/.local/bin/herdr")"
if [ -x "$herdr_bin" ]; then
  if ! "$herdr_bin" plugin list 2>/dev/null | grep -q 'ray.file-explorer'; then
    log "Installing the herdr-yazi plugin..."
    PATH="$HOME/.local/bin:$PATH" "$herdr_bin" plugin install speardragon/herdr-yazi --yes >/dev/null 2>&1 \
      || warn "herdr-yazi plugin install failed - run: herdr plugin install speardragon/herdr-yazi"
  else
    log "OK: herdr-yazi plugin"
  fi
  herdr_cfg="$HOME/.config/herdr/config.toml"
  if ! grep -q 'ray.file-explorer.open' "$herdr_cfg" 2>/dev/null; then
    mkdir -p "$(dirname "$herdr_cfg")"
    cat >> "$herdr_cfg" <<'HERDR_KEYS'

# --- herdr-yazi keys (added by dotfiles/install.sh; see docs/yazi.md) ---
[[keys.command]]
key = "prefix+y"
type = "plugin_action"
command = "ray.file-explorer.open"
description = "yazi: open file explorer (split)"

[[keys.command]]
key = "prefix+Y"
type = "plugin_action"
command = "ray.file-explorer.open-tab"
description = "yazi: open file explorer (new tab)"
HERDR_KEYS
    log "Added herdr-yazi keys to $herdr_cfg"
    "$herdr_bin" server reload-config >/dev/null 2>&1 || true
  else
    log "OK: herdr-yazi keys"
  fi
fi

# --- 4b. herdr: sidebar (trial) -----------------------------------------------------
# herdr-sidebar: VS Code-style explorer + source control docked beside the panes
# (docs/herdr-sidebar.md). On trial since 2026-10-09; in dotfiles so it can be
# tried on every machine. Same pattern as 4a. The manifest lives in a
# subdirectory of the repo, hence the long install path. Its build fetches a
# prebuilt binary where upstream ships one, else builds from source (needs Rust).
if [ -x "$herdr_bin" ]; then
  if ! "$herdr_bin" plugin list 2>/dev/null | grep -q '^- herdr-sidebar '; then
    log "Installing the herdr-sidebar plugin..."
    # Pin the latest release tag: a bare install takes main's HEAD, which the
    # plugin's own "Update sidebar" action treats as a preview and never moves
    # back to stable (seen on GeekForge 2026-10-09).
    sidebar_url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/alexarthurs/herdr-sidebar/releases/latest)"
    PATH="$HOME/.local/bin:$PATH" "$herdr_bin" plugin install alexarthurs/herdr-sidebar/plugins/herdr-sidebar \
      --ref "${sidebar_url##*/}" --yes >/dev/null 2>&1 \
      || warn "herdr-sidebar plugin install failed - run: herdr plugin install alexarthurs/herdr-sidebar/plugins/herdr-sidebar"
  else
    log "OK: herdr-sidebar plugin"
  fi
  if ! grep -q 'herdr-sidebar.open-sidebar' "$herdr_cfg" 2>/dev/null; then
    cat >> "$herdr_cfg" <<'HERDR_KEYS'

# --- herdr-sidebar keys (added by dotfiles/install.sh; see docs/herdr-sidebar.md) ---
# Not e/p/g: herdr already uses prefix+e (edit scrollback), p (previous tab), g (goto).
[[keys.command]]
key = "prefix+f"
type = "plugin_action"
command = "herdr-sidebar.open-sidebar"
description = "sidebar: toggle"

[[keys.command]]
key = "prefix+shift+f"
type = "plugin_action"
command = "herdr-sidebar.quick-open"
description = "sidebar: quick open file"

[[keys.command]]
key = "prefix+d"
type = "plugin_action"
command = "herdr-sidebar.show-git"
description = "sidebar: source control"
HERDR_KEYS
    log "Added herdr-sidebar keys to $herdr_cfg"
    "$herdr_bin" server reload-config >/dev/null 2>&1 || true
  else
    log "OK: herdr-sidebar keys"
  fi
fi

# --- 4b. Claude Code status line ---------------------------------------------------
# The rows under Claude Code's prompt (model, effort, repo, branch, context bar,
# cost, cache, rate limits) come from claude/statusline.py. Claude Code only runs
# it if ~/.claude/settings.json names it under "statusLine", so besides the
# symlink we add that key when it is missing. Existing keys are never touched,
# and an existing "statusLine" (even a different one) is left alone.
link "$DOTFILES/claude/statusline.py" "$HOME/.claude/statusline/statusline.py"
chmod +x "$DOTFILES/claude/statusline.py"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$HOME/.claude/settings.json" "$HOME/.claude/statusline/statusline.py" <<'EOF'
import json, os, sys
path, script = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        cfg = json.load(f)
except FileNotFoundError:
    cfg = {}
if "statusLine" in cfg:
    print(f"\033[1;32m[dotfiles]\033[0m OK: statusLine already set in {path}")
    sys.exit(0)
cfg["statusLine"] = {"type": "command", "command": script,
                     "padding": 0, "refreshInterval": 60}
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"\033[1;32m[dotfiles]\033[0m Added statusLine to {path}")
EOF
else
  warn "python3 not found — statusline.py needs it; skipped the settings.json edit."
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
