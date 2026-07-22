# dotfiles

My portable terminal environment: **zsh + Oh My Posh (atomic) + fzf + autosuggestions +
syntax highlighting**, plus git, WezTerm and Terminator configs. One command sets up any
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
   `wezterm@nightly` and `font-fira-code-nerd-font` casks.
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
   | `bin/mount-excemca` | `~/.local/bin/mount-excemca` |

5. Creates an empty `~/.zshrc.local` for machine-specific config.

### macOS notes

- Requires [Homebrew](https://brew.sh) — the installer stops early if it's missing.
- WezTerm is installed as a cask, so it lands in `/Applications` and its CLI is
  linked into `/opt/homebrew/bin`. Updates come from `brew upgrade --cask`, which
  is why `check_for_updates` stays off in the config.
- **Do not move WezTerm.app out of `/Applications`.** The cask's CLI symlink is
  absolute (`/opt/homebrew/bin/wezterm` → `/Applications/WezTerm.app/...`), so
  filing the app into a subfolder leaves it dangling: `wezterm` disappears from
  `$PATH` and `wezterm connect geekforge` stops working, while the GUI keeps
  launching normally — which makes it look like nothing is wrong. Repoint the
  symlink or `brew reinstall --cask wezterm@nightly` to recover.
- **Nightly, not stable.** Upstream's last stable is `20240203`; Fedora tracks the
  `wezterm-nightly` COPR, so macOS uses the `wezterm@nightly` cask to stay on the
  same build. The plain `wezterm` cask conflicts with it (same linked binaries) —
  `brew uninstall --cask wezterm` first if a machine has it.
- The zshrc runs `brew shellenv` before anything else, so Apple Silicon
  (`/opt/homebrew`) and Intel (`/usr/local`) both work with no edits.
- Oh My Zsh is not used. If a machine already has it, `install.sh` backs up the
  old `~/.zshrc`; `~/.oh-my-zsh` is left untouched, so reverting is just a matter
  of restoring the backup.

## Layout

```
├── install.sh                # setup script (Fedora + Debian/Ubuntu + macOS)
├── install.ps1               # setup script (Windows-native: WezTerm, font, prompt, profile)
├── zsh/.zshrc                # portable zshrc — degrades gracefully if a tool is missing
├── git/.gitconfig
├── wezterm/wezterm.lua       # one config for Linux, macOS and Windows
├── terminator/config         # FiraCode Nerd Font profile (Linux only)
├── bin/clip2forge            # push desktop clipboard to GeekForge (Wayland/X11/macOS)
├── bin/mount-excemca         # mount the GeekLab excemca SMB share (Linux cifs / macOS smbfs)
├── ohmyposh/atomic.omp.json  # vendored theme, copied to ~/.config/ohmyposh/
└── windows/
    └── Microsoft.PowerShell_profile.ps1   # light native-Windows profile (installed by install.ps1)
```

## WezTerm keybindings

Terminator muscle memory, so the same keys work on every machine. The native
`Cmd+C/V/T/N/W` defaults keep working on macOS alongside these.

| Keys | Action |
| :--- | :--- |
| `Ctrl+Shift+E` / `Ctrl+Shift+O` | Split side by side / stacked |
| `Cmd+D` / `Cmd+Shift+D` | Same, macOS-native muscle memory |
| `Ctrl+Shift+W` | Close **pane** (wezterm's default closes the tab) |
| `Ctrl+Shift+X` | Zoom pane |
| `Alt+arrows` | Move between panes |
| `Ctrl+Shift+Alt+arrows` | Resize pane |
| `Ctrl+Shift+K` | **Copy mode** — select and copy with the keyboard |
| `Ctrl+Shift+Space` | **QuickSelect** — hint-jump to URLs, paths, hashes |
| `Ctrl+Shift+F` | Search scrollback |
| `F2` | Rename tab (empty input restores the automatic title) |

**Copying out of a full-screen TUI** (claude, vim, k9s) needs one of these: the app
captures the mouse, so dragging selects nothing. Either hold **Shift while dragging**
to bypass mouse reporting, or skip the mouse entirely with copy mode / QuickSelect.
This is the single most-forgotten thing in this config, which is why it is written
down here.

`Ctrl+Shift+X` is deliberately zoom rather than wezterm's default copy mode — copy
mode moved to `Ctrl+Shift+K` to keep the terminator layout intact.

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
native side (WezTerm, Nerd Font, prompt, PowerShell profile) is set up by `install.ps1`.

```powershell
# from the repo root, in PowerShell:
.\install.ps1
```

`install.ps1` is idempotent and backs up anything it replaces. It installs WezTerm +
FiraCode Nerd Font + Oh My Posh via `winget`, writes a `~/.wezterm.lua` loader that
points at `wezterm/wezterm.lua`, and dot-sources `windows/Microsoft.PowerShell_profile.ps1`
from `$PROFILE`.

Then set up the shell in WSL (the same zsh everywhere):

```powershell
wsl --install -d Debian          # admin; skip if WSL is already set up
```
```bash
# inside WSL:
git clone https://github.com/jacedeno/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles && ./install.sh
```

WezTerm launches WSL by default (`default_prog = { "wsl.exe", "--cd", "~" }`); the
PowerShell profile stays light for native tasks. Swap `default_prog` in
`wezterm/wezterm.lua` if you'd rather default to PowerShell.
