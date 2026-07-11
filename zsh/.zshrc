# ==============================================================================
# ~/.zshrc — jacedeno dotfiles
# Portable across Fedora / Debian / Ubuntu. Machine-specific settings go in
# ~/.zshrc.local (sourced at the end, never committed).
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
alias ll="ls -lah --color=auto"
alias la="ls -A --color=auto"
alias l="ls -CF --color=auto"

# --- Aliases: package manager (per distro) --------------------------------------
if command -v dnf >/dev/null 2>&1; then
  alias pkgu="sudo dnf upgrade --refresh"
  alias pkgi="sudo dnf install"
  alias pkgs="dnf search"
  alias pkgr="sudo dnf remove"
  alias pkgls="dnf list installed"
elif command -v apt >/dev/null 2>&1; then
  alias pkgu="sudo apt update && sudo apt upgrade"
  alias pkgi="sudo apt install"
  alias pkgs="apt search"
  alias pkgr="sudo apt remove"
  alias pkgls="apt list --installed"
fi

# --- Aliases: system utilities --------------------------------------------------
alias cls="clear"
alias myip="curl -s ifconfig.me && echo"
alias ports="ss -tulanp"
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

# --- Aliases: quick config edit --------------------------------------------------
alias zconf='${EDITOR:-nano} ~/.zshrc'
alias zreload='source ~/.zshrc'
alias termconfig='${EDITOR:-nano} ~/.config/terminator/config'
alias wezconfig='${EDITOR:-nano} ~/.config/wezterm/wezterm.lua'

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
