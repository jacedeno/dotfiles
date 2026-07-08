# dotfiles

My portable terminal environment: **zsh + Oh My Posh (atomic) + fzf + autosuggestions +
syntax highlighting**, plus git and Terminator configs. One command sets up any fresh
Fedora or Debian/Ubuntu machine.

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

1. Installs packages (`zsh`, `git`, `curl`, `fzf`) via `dnf` or `apt`.
2. Installs [Oh My Posh](https://ohmyposh.dev) to `~/.local/bin` and pins the
   `atomic` theme locally (`~/.config/ohmyposh/atomic.omp.json`) so the prompt
   works offline.
3. Clones [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and
   [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
   into `~/.zsh/plugins/`.
4. Symlinks the dotfiles into place:

   | Repo file | Symlinked to |
   | :--- | :--- |
   | `zsh/.zshrc` | `~/.zshrc` |
   | `git/.gitconfig` | `~/.gitconfig` |
   | `terminator/config` | `~/.config/terminator/config` (only if Terminator is installed) |

5. Creates an empty `~/.zshrc.local` for machine-specific config.

## Layout

```
├── install.sh                # setup script (Fedora + Debian/Ubuntu)
├── zsh/.zshrc                # portable zshrc — degrades gracefully if a tool is missing
├── git/.gitconfig
├── terminator/config         # FiraCode Nerd Font profile
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
- **Distro-neutral package aliases.** `pkgi` / `pkgu` / `pkgr` / `pkgs` map to
  `dnf` on Fedora and `apt` on Debian/Ubuntu.
- **Nerd Font required for the prompt glyphs.** Terminator profile expects
  *FiraCode Nerd Font Mono* — grab it from [nerdfonts.com](https://www.nerdfonts.com/)
  if the prompt shows broken symbols.

## Windows

Copy `windows/Microsoft.PowerShell_profile.ps1` to `$PROFILE`
(`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`) and install
Oh My Posh with `winget install JanDeDobbeleer.OhMyPosh`.
