# ==============================================================================
# ~/.zshrc — jacedeno dotfiles
# Portable across Fedora / Debian / Ubuntu. Machine-specific settings go
# in ~/.zshrc.local (sourced at the end, never committed).
# ==============================================================================

# --- PATH -------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# --- Prompt: Oh My Posh (atomic theme) ----------------------------------------
# install.sh drops the theme at ~/.config/ohmyposh/atomic.omp.json.
# Falls back to the remote theme, then to the plain prompt.
if command -v oh-my-posh >/dev/null 2>&1; then
  if [ -f "$HOME/.config/ohmyposh/atomic.omp.json" ]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/atomic.omp.json")"
  else
    eval "$(oh-my-posh init zsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/atomic.omp.json)"
  fi
fi

# --- History ------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST

# --- Completion ---------------------------------------------------------------
autoload -Uz compinit && compinit

# --- Plugins (installed by install.sh into ~/.zsh/plugins) ---------------------
if [ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=cyan"
  export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# --- FZF ------------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  # fzf >= 0.48 ships --zsh; older distro packages ship key-binding files.
  if fzf --zsh >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
  else
    for f in /usr/share/doc/fzf/examples/key-bindings.zsh \
             /usr/share/fzf/shell/key-bindings.zsh; do
      [ -f "$f" ] && source "$f" && break
    done
  fi

  # Tokyo Night-inspired palette (matches the atomic prompt)
  export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border rounded
    --color=fg:#c0caf5,bg:#1a1b26,hl:#ff9e64
    --color=fg+:#c0caf5,bg+:#292e42,hl+:#ff9e64
    --color=info:#7aa2f7,prompt:#7dcfff,pointer:#f7768e
    --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
  "
  export FZF_CTRL_T_OPTS="--preview 'cat -n {}' --preview-window=right:60%:wrap"
fi

# --- Aliases: navigation --------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# --- Aliases: listing -----------------------------------------------------------
# GNU ls takes --color=auto; BSD ls takes -G. Probe instead of assuming.
if ls --color=auto . >/dev/null 2>&1; then
  _ls_color="--color=auto"
else
  _ls_color="-G"
fi
alias ll="ls -lah $_ls_color"
alias la="ls -A $_ls_color"
alias l="ls -CF $_ls_color"
unset _ls_color

# --- Aliases: package manager (per platform) ------------------------------------
# The native manager wins: a Linux box running Linuxbrew alongside dnf/apt should
# still get dnf/apt here. brew stays as a last-resort fallback.
if command -v dnf >/dev/null 2>&1; then
  alias pkgu="sudo dnf upgrade --refresh"
  alias pkgi="sudo dnf install"
  alias pkgs="dnf search"
  alias pkgr="sudo dnf remove"
  alias pkgls="dnf list installed"
  _sys_update() { sudo dnf upgrade --refresh -y; }      # one-shot: refresh + upgrade
  _sys_clean() { sudo dnf autoremove -y && sudo dnf clean all; }  # orphans + caches
elif command -v apt >/dev/null 2>&1; then
  alias pkgu="sudo apt update && sudo apt upgrade"
  alias pkgi="sudo apt install"
  alias pkgs="apt search"
  alias pkgr="sudo apt remove"
  alias pkgls="apt list --installed"
  _sys_update() { sudo apt update && sudo apt upgrade -y; }   # one-shot: refresh + upgrade
  # rc = removed but config left behind; old kernels pile up here (16 on GeekForge).
  _sys_clean() {
    sudo apt autoremove --purge -y && sudo apt autoclean
    local rc; rc=(${(f)"$(dpkg -l | awk '/^rc/{print $2}')"})
    (( $#rc )) && sudo dpkg --purge "${rc[@]}"
  }
elif command -v brew >/dev/null 2>&1; then
  alias pkgu="brew update && brew upgrade"
  alias pkgi="brew install"
  alias pkgs="brew search"
  alias pkgr="brew uninstall"
  alias pkgls="brew list"
  _sys_update() { brew update && brew upgrade; }              # one-shot: refresh + upgrade
  _sys_clean() { brew cleanup; }                              # old versions + caches
fi

# update: system packages + everything installed outside the package manager,
# in one shot: Oh My Posh, the zsh plugins (git clones), claude and herdr.
# herdr goes through bin/herdr-update, which handles the inside-a-pane guard
# and the live server handoff; plain `herdr update` refuses to run from a pane.
update() {
  _sys_update
  # Only the ~/.local/bin copy is ours to upgrade. A distro package (C2-B5's
  # /usr/bin RPM) is already covered by _sys_update, and the major-bump
  # reinstall below would drop a second copy in ~/.local/bin that shadows it.
  if [[ "$(command -v oh-my-posh)" == "$HOME/.local/bin/oh-my-posh" ]]; then
    echo "\n==> oh-my-posh upgrade"
    # Minor/patch bumps just happen. A major bump only prints a warning and
    # asks for --force, and --force is a silent no-op (seen on 29.6.1 ->
    # 31.3.0, 2026-09-21), so on that warning we rerun the official installer
    # into ~/.local/bin — the same thing install.sh does on a fresh machine.
    local omp_out; omp_out="$(oh-my-posh upgrade 2>&1)"; echo "$omp_out"
    if [[ "$omp_out" == *"major upgrade available"* ]]; then
      echo "major bump: reinstalling via the official installer"
      curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
      echo "oh-my-posh now $(oh-my-posh version)"
    fi
  fi
  local plugin
  for plugin in "$HOME"/.zsh/plugins/*/.git; do
    [ -d "$plugin" ] || continue
    echo "\n==> git pull $(basename "${plugin:h}")"; git -C "${plugin:h}" pull --ff-only -q && echo "up to date: $(git -C "${plugin:h}" log --oneline -1)"
  done
  if command -v claude >/dev/null 2>&1; then
    echo "\n==> claude update"; claude update
  fi
  if command -v herdr-update >/dev/null 2>&1; then
    echo "\n==> herdr-update"; herdr-update
  fi
}

# clean: package orphans and caches, then what update and the tools it drives
# leave behind. Everything deleted is regenerable or already dead. What holds
# history (Claude transcripts + memory of a deleted repo, the trash) is only
# reported, never removed.
clean() {
  local before; before=$(df -k --output=avail "$HOME" | tail -1)
  _sys_clean
  if command -v flatpak >/dev/null 2>&1; then
    echo "\n==> flatpak unused runtimes"; flatpak uninstall --unused -y
  fi
  echo "\n==> journal older than 4 weeks"; sudo journalctl --vacuum-time=4weeks
  local c
  for c in docker podman; do
    command -v $c >/dev/null 2>&1 && $c info >/dev/null 2>&1 || continue
    echo "\n==> $c dangling images"; $c image prune -f
  done

  echo "\n==> tool caches"
  command -v uv >/dev/null 2>&1 && uv cache prune
  command -v pip >/dev/null 2>&1 && pip cache purge
  command -v go >/dev/null 2>&1 && go clean -cache && echo "go build cache cleared"
  command -v pnpm >/dev/null 2>&1 && pnpm store prune
  command -v npm >/dev/null 2>&1 && npm cache verify >/dev/null && echo "npm cache garbage-collected"
  # One init script per config hash, never pruned by oh-my-posh itself.
  if [ -d "$HOME/.cache/oh-my-posh" ]; then
    echo "oh-my-posh: $(find "$HOME/.cache/oh-my-posh" -name 'init.*' -mtime +7 -delete -print | wc -l) stale init scripts removed"
  fi

  # Keep the version ~/.local/bin/claude points at plus the newest other one,
  # so a rollback is still one symlink away.
  local vdir="$HOME/.local/share/claude/versions"
  if [ -d "$vdir" ] && [ -L "$HOME/.local/bin/claude" ]; then
    local cur prev v; cur=${$(readlink -f "$HOME/.local/bin/claude"):t}
    prev=$(ls -v "$vdir" | grep -vxF "$cur" | tail -1)
    echo "\n==> claude versions (keeping $cur${prev:+ and $prev})"
    for v in "$vdir"/*(N); do
      [[ ${v:t} == "$cur" || ${v:t} == "$prev" ]] && continue
      rm -rf -- "$v" && echo "removed ${v:t}"
    done
  fi

  # Self-updaters (agy, herdr) leave the replaced binary as *.old / *.bak;
  # (-@) is a symlink whose target is gone.
  echo "\n==> ~/.local/bin leftovers"
  local f
  for f in "$HOME"/.local/bin/*.(old|bak)(N) "$HOME"/.local/bin/*(N-@); do
    rm -f -- "$f" && echo "removed ${f:t}"
  done

  echo "\n==> claude projects whose directory is gone (not removed: transcripts + memory)"
  local d j cwd
  for d in "$HOME"/.claude/projects/*(N/); do
    j=("$d"/*.jsonl(N.om[1])); (( $#j )) || continue
    cwd=$(grep -m1 -o '"cwd":"[^"]*"' "$j[1]" | cut -d'"' -f4)
    [[ -n $cwd && ! -d $cwd ]] && echo "$(du -sh "$d" | cut -f1)  ${d:t}  (was $cwd)"
  done

  if [ -d "$HOME/.local/share/Trash/files" ] && [ -n "$(ls -A "$HOME/.local/share/Trash/files")" ]; then
    echo "\n==> trash (not emptied): $(du -sh "$HOME/.local/share/Trash" | cut -f1) — gio trash --empty"
  fi

  local after; after=$(df -k --output=avail "$HOME" | tail -1)
  echo "\n==> freed $(( (after - before) / 1024 )) MB on $(df --output=target "$HOME" | tail -1); $(df -h --output=avail "$HOME" | tail -1 | tr -d ' ') available"
}

# --- Aliases: system utilities --------------------------------------------------
alias cls="clear"
alias myip="curl -s ifconfig.me && echo"
# ss is iproute2; lsof is the closest equivalent where it is missing.
if command -v ss >/dev/null 2>&1; then
  alias ports="ss -tulanp"
else
  alias ports="lsof -nP -iTCP -sTCP:LISTEN -iUDP"
fi
alias grep="grep --color=auto"
alias df="df -h"
alias du="du -sh"

# --- Aliases: safety nets -------------------------------------------------------
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -Iv"

# --- Aliases: git ----------------------------------------------------------------
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate -15"
alias gd="git diff"

# --- Aliases: Antigravity CLI ----------------------------------------------------
alias agy-yolo='agy --dangerously-skip-permissions'

# --- Aliases: quick config edit --------------------------------------------------
alias zconf='${EDITOR:-nano} ~/.zshrc'
alias zreload='source ~/.zshrc'
alias alacrittyconfig='${EDITOR:-nano} ~/.config/alacritty/alacritty.toml'

# --- Kubernetes -------------------------------------------------------------------
if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
  alias kgp='kubectl get pods'
  alias kgpa='kubectl get pods -A'
  alias kga='kubectl get all'
  alias kgn='kubectl get nodes'
  alias kgs='kubectl get svc'
  alias klf='kubectl logs -f'
  alias kdp='kubectl describe pod'
  alias kns="kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}{\"\n\"}'"
  source <(kubectl completion zsh)
  compdef __start_kubectl k
fi

# --- Functions ---------------------------------------------------------------------
# Create a directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any compressed file automatically
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.rar)     unrar x "$1" ;;
      *.7z)      7z x "$1" ;;
      *)         echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# --- Syntax highlighting (must load last among plugins) -----------------------------
if [ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- Machine-specific overrides (nvm, platformio, work PATHs, extra aliases) --------
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
