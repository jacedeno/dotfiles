# dotfiles

My portable terminal environment: **zsh + Oh My Posh (atomic) + fzf + autosuggestions +
syntax highlighting**, plus git and Alacritty configs. One command sets up any
fresh Fedora, Debian/Ubuntu or macOS machine — and on Windows, `install.ps1` for the
native side plus WSL for the same zsh shell.

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
   `font-fira-code-nerd-font` cask.
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
   | `git/hooks` | `~/.config/git/hooks` (global `core.hooksPath`; `commit-msg` rejects AI attribution) |
   | `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` (only if Alacritty is installed) |
   | `environment.d/10-local-bin.conf` | `~/.config/environment.d/10-local-bin.conf` (only if `systemctl` is present) — puts `~/.local/bin` on `PATH` for GUI/dbus-launched apps, which never source `~/.zshrc`. Takes effect on next login. |
   | `bin/clip2forge` | `~/.local/bin/clip2forge` |
   | `bin/mount-excemca` | `~/.local/bin/mount-excemca` |

5. Creates an empty `~/.zshrc.local` for machine-specific config. Git identity and
   other machine-specific git settings go in `~/.gitconfig.local` (untracked), which
   the tracked `.gitconfig` includes last so its values win.

### macOS notes

- Requires [Homebrew](https://brew.sh) — the installer stops early if it's missing.
- No terminal emulator is installed here: `install.sh` only ships the Nerd Font
  cask, and `alacritty/alacritty.toml` is linked only if Alacritty is already
  present. Install it yourself (`brew install --cask alacritty`) if you want it.
- The zshrc runs `brew shellenv` before anything else, so Apple Silicon
  (`/opt/homebrew`) and Intel (`/usr/local`) both work with no edits.
- Oh My Zsh is not used. If a machine already has it, `install.sh` backs up the
  old `~/.zshrc`; `~/.oh-my-zsh` is left untouched, so reverting is just a matter
  of restoring the backup.

## Layout

```
├── install.sh                # setup script (Fedora + Debian/Ubuntu + macOS)
├── install.ps1               # setup script (Windows-native: git, font, prompt, profile)
├── zsh/.zshrc                # portable zshrc — degrades gracefully if a tool is missing
├── git/.gitconfig
├── alacritty/alacritty.toml  # the terminal — Tokyo Night on black, launches herdr
├── environment.d/10-local-bin.conf  # puts ~/.local/bin on PATH for GUI/dbus-launched apps (systemd --user)
├── bin/clip2forge            # push desktop clipboard to GeekForge (Wayland/X11/macOS)
├── bin/mount-excemca         # mount the GeekLab excemca SMB share (Linux cifs / macOS smbfs)
├── ohmyposh/atomic.omp.json  # vendored theme, copied to ~/.config/ohmyposh/
├── machines/                 # per-machine hardware notes (docs only, never installed)
│   ├── gimble.md             # Chromebook + MrChromebox running Fedora — Alacritty+herdr, default terminal
│   └── ThinkPadT470.md       # personal work laptop, Fedora — Alacritty+herdr terminal swap
└── windows/
    └── Microsoft.PowerShell_profile.ps1   # light native-Windows profile (installed by install.ps1)
```

## Machines

The configs are portable by design, but some boxes need workarounds a dotfile
cannot carry — firmware quirks, driver overrides, hardware that only half works.
Those are documented in [`machines/`](machines/), which `install.sh` never touches.

| Machine | Notes |
| :--- | :--- |
| [`gimble`](machines/gimble.md) | Google Chromebook reflashed with MrChromebox, running Fedora. Touchpad scroll tuning, dead webcam, Bluetooth workarounds. Also on Alacritty + herdr, and the only machine where it is GNOME's *default* terminal (needs `xdg-terminal-exec`). |
| [`ThinkPadT470`](machines/ThinkPadT470.md) | Personal work laptop, Fedora. First machine on Alacritty + herdr instead of WezTerm — herdr owns tabs/splits/persistence since Alacritty has none. |

## Terminal: Alacritty + herdr

Alacritty is the emulator; it has no tabs or panes of its own, so
`alacritty/alacritty.toml` sets `terminal.shell = herdr` and every window
attaches to herdr's persistent local session. **Splits, tabs and detach are
herdr's bindings** (`ctrl+b` prefix), not Alacritty's — see herdr's own docs.

What the repo config binds directly:

| Keys | Action |
| :--- | :--- |
| `Ctrl+Shift+K` | Toggle **vi mode** — select and copy with the keyboard |
| Right click | Paste |

To get a plain zsh with no herdr in the way: `alacritty -e /usr/bin/zsh`.

**Copying out of a full-screen TUI** (claude, vim, k9s) needs one of these: the app
captures the mouse, so dragging selects nothing. Either hold **Shift while dragging**
to bypass mouse reporting, or skip the mouse entirely with `Ctrl+Shift+K`. This is
the single most-forgotten thing in this config, which is why it is written down here.

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

The shell on Windows is **WSL** — it runs the exact same zsh + dotfiles as the Linux
machines, so aliases, prompt and config are identical with nothing duplicated. The
native side (git, Nerd Font, prompt, PowerShell profile) is set up by `install.ps1`.
No terminal emulator is installed: Windows Terminal already ships with Windows.

```powershell
# from the repo root, in PowerShell:
.\install.ps1
```

`install.ps1` is idempotent and backs up anything it replaces. It installs Git +
Oh My Posh via `winget`, the FiraCode Nerd Font via `oh-my-posh font install`, and
dot-sources `windows/Microsoft.PowerShell_profile.ps1` from `$PROFILE`.

Then set up the shell in WSL (the same zsh everywhere):

```powershell
wsl --install -d Debian          # admin; skip if WSL is already set up
```
```bash
# inside WSL:
git clone https://github.com/jacedeno/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles && ./install.sh
```

Set the WSL distro as Windows Terminal's default profile to land straight in zsh;
the PowerShell profile stays light for native tasks.
