# dotfiles

My portable terminal environment: **zsh + Oh My Posh (atomic) + fzf + autosuggestions +
syntax highlighting**, plus git, WezTerm and Terminator configs. One command sets up any
fresh Fedora, Debian/Ubuntu or macOS machine.

## Quick start

```bash
git clone https://github.com/jacedeno/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
./install.sh
exec zsh
```

`install.sh` is **idempotent** — safe to re-run any time. It never overwrites your
existing files: anything in the way is moved to `~/.dotfiles-backup/<timestamp>/`.

## What it does

1. Installs packages: `zsh`, `git`, `curl`, `fzf` via `dnf`/`apt` on Linux —
   `git`, `fzf` via `brew` on macOS (zsh and curl already ship with it), plus the
   `wezterm` and `font-fira-code-nerd-font` casks.
2. Installs [Oh My Posh](https://ohmyposh.dev) (`brew` on macOS, otherwise the
   upstream installer into `~/.local/bin`) and pins the `atomic` theme locally
   (`~/.config/ohmyposh/atomic.omp.json`) so the prompt works offline.
3. Clones [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and
   [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
   into `~/.zsh/plugins/`.
4. Symlinks the dotfiles into place:

   | Repo file | Symlinked to |
   | :--- | :--- |
   | `zsh/.zshrc` | `~/.zshrc` |
   | `git/.gitconfig` | `~/.gitconfig` |
   | `wezterm/wezterm.lua` | `~/.config/wezterm/wezterm.lua` (only if WezTerm is installed) |
   | `terminator/config` | `~/.config/terminator/config` (only if Terminator is installed) |
   | `bin/clip2forge` | `~/.local/bin/clip2forge` |

5. Creates an empty `~/.zshrc.local` for machine-specific config.

### macOS notes

- Requires [Homebrew](https://brew.sh) — the installer stops early if it's missing.
- WezTerm is installed as a cask, so it lands in `/Applications` and its CLI is
  linked into `/opt/homebrew/bin`. Updates come from `brew upgrade --cask`, which
  is why `check_for_updates` stays off in the config.
- The zshrc runs `brew shellenv` before anything else, so Apple Silicon
  (`/opt/homebrew`) and Intel (`/usr/local`) both work with no edits.
- Oh My Zsh is not used. If a machine already has it, `install.sh` backs up the
  old `~/.zshrc`; `~/.oh-my-zsh` is left untouched, so reverting is just a matter
  of restoring the backup.

## Layout

```
├── install.sh                # setup script (Fedora + Debian/Ubuntu + macOS)
├── zsh/.zshrc                # portable zshrc — degrades gracefully if a tool is missing
├── git/.gitconfig
├── wezterm/wezterm.lua       # one config for Linux, macOS and Windows
├── terminator/config         # FiraCode Nerd Font profile (Linux only)
├── bin/clip2forge            # push desktop clipboard to GeekForge (Wayland/X11/macOS)
├── ohmyposh/atomic.omp.json  # vendored theme, copied to ~/.config/ohmyposh/
└── windows/
    └── Microsoft.PowerShell_profile.ps1   # PowerShell equivalent (manual install)
```

## Design notes

- **Portable core, local overrides.** `~/.zshrc` is identical on every machine.
  Anything machine-specific (nvm, PlatformIO, work PATHs, extra aliases) lives in
  `~/.zshrc.local`, which is sourced last and never committed.
- **Guards everywhere.** Every tool integration (`oh-my-posh`, `fzf`, `kubectl`,
  plugins) is wrapped in existence checks, so the same zshrc works on a minimal
  server and a full workstation.
- **Platform-neutral package aliases.** `pkgi` / `pkgu` / `pkgr` / `pkgs` map to
  `dnf` on Fedora, `apt` on Debian/Ubuntu and `brew` on macOS.
- **Probe, don't assume.** Where GNU and BSD userland differ, the zshrc tests the
  tool instead of branching on the OS: `ll` uses `--color=auto` where it works and
  falls back to BSD `-G`; `ports` uses `ss` where present, else `lsof`.
- **Nerd Font required for the prompt glyphs.** Everything expects *FiraCode Nerd
  Font Mono*. macOS installs it via cask; on Linux grab it from
  [nerdfonts.com](https://www.nerdfonts.com/) if the prompt shows broken symbols.

## Windows

Copy `windows/Microsoft.PowerShell_profile.ps1` to `$PROFILE`
(`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`) and install
Oh My Posh with `winget install JanDeDobbeleer.OhMyPosh`.
