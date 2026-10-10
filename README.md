# dotfiles

My portable terminal environment: **zsh + Oh My Posh (atomic) + fzf + autosuggestions +
syntax highlighting**, plus git and Alacritty configs. One command sets up any
fresh Fedora or Debian/Ubuntu machine — and on Windows, `install.ps1` for the
native side plus WSL for the same zsh shell. No macOS: there is no Mac in the fleet
(support dropped 2026-09-14).

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

1. Installs packages: `zsh`, `git`, `curl`, `fzf`, `unzip`, `tree` via
   `dnf` (Fedora) or `apt` (Debian/Ubuntu), plus [Yazi](https://yazi-rs.github.io) (terminal
   file manager) from its upstream release into `~/.local/bin`, since no distro packages it.
2. Installs [Oh My Posh](https://ohmyposh.dev) with the upstream installer into
   `~/.local/bin` and pins the `atomic` theme locally
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
   | `fontconfig/fonts.conf` | `~/.config/fontconfig/fonts.conf` (only if Alacritty is installed) — color emoji, see [Color emoji](#color-emoji); `install.sh` also downloads the font it needs |
   | `environment.d/10-local-bin.conf` | `~/.config/environment.d/10-local-bin.conf` (only if `systemctl` is present) — puts `~/.local/bin` on `PATH` for GUI/dbus-launched apps, which never source `~/.zshrc`. Takes effect on next login. |
   | `bin/clip2forge` | `~/.local/bin/clip2forge` |
   | `bin/mount-excemca` | `~/.local/bin/mount-excemca` |
   | `bin/yazi-update` | `~/.local/bin/yazi-update` — installs or upgrades yazi from its upstream release; run by `install.sh` and `update` |
   | `claude/statusline.py` | `~/.claude/statusline/statusline.py` — Claude Code's status line; `install.sh` also adds the `statusLine` key to `~/.claude/settings.json` if it is missing (see [Claude Code status line](#claude-code-status-line)) |

5. Creates an empty `~/.zshrc.local` for machine-specific config. Git identity and
   other machine-specific git settings go in `~/.gitconfig.local` (untracked), which
   the tracked `.gitconfig` includes last so its values win.

### Notes

- No terminal emulator is installed: `alacritty/alacritty.toml` is linked only if
  Alacritty is already present.
- Oh My Zsh is not used. If a machine already has it, `install.sh` backs up the
  old `~/.zshrc`; `~/.oh-my-zsh` is left untouched, so reverting is just a matter
  of restoring the backup.

## Layout

```
├── install.sh                # setup script (Fedora + Debian/Ubuntu)
├── install.ps1               # setup script (Windows-native: git, font, prompt, profile)
├── zsh/.zshrc                # portable zshrc — degrades gracefully if a tool is missing
├── git/.gitconfig
├── alacritty/alacritty.toml  # the terminal — Tokyo Night on black, launches herdr
├── fontconfig/fonts.conf     # color emoji in Alacritty — bitmap Noto Color Emoji wins over COLRv1/Symbola
├── environment.d/10-local-bin.conf  # puts ~/.local/bin on PATH for GUI/dbus-launched apps (systemd --user)
├── bin/clip2forge            # push desktop clipboard to GeekForge (Wayland/X11)
├── bin/mount-excemca         # mount a GeekLab SMB share — excemca (default) or -f for Family Share
├── bin/herdr-update          # update herdr from inside a herdr pane — live handoff, panes survive
├── bin/yazi-update           # install/upgrade yazi in ~/.local/bin from the upstream release
├── claude/statusline.py      # Claude Code status line — model, effort, repo/branch, context bar, cost, cache, rate limits
├── ohmyposh/atomic.omp.json  # vendored theme, copied to ~/.config/ohmyposh/
├── docs/
│   ├── yazi.md               # tree + yazi: browsing files as a hierarchy in the terminal, keys and usage
│   ├── yazi-cheatsheet.html  # the same keys as a printable one-page cheatsheet
│   └── herdr-sidebar.md      # VS Code-style sidebar plugin for herdr (on trial) — keys, rollout, removal
├── machines/                 # per-machine hardware notes (docs only, never installed)
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

### Color emoji

Fedora ships *Noto Color Emoji* only in the COLRv1 (vector) format, which
Alacritty cannot paint, so fontconfig falls back to monochrome *Symbola* and the
herdr-sidebar icons come out as outlines. `install.sh` downloads the bitmap
(CBDT) build, `NotoColorEmoji.ttf` from
[googlefonts/noto-emoji](https://github.com/googlefonts/noto-emoji) (`2D/fonts/`),
into `~/.local/share/fonts/`, and `fontconfig/fonts.conf` hides the COLRv1 build
and Symbola so it always wins. Restart Alacritty after the first install.

The downloaded font never updates itself; to pick up newer emoji, delete it and
re-run `install.sh`. Check what a glyph resolves to with
`fc-match "FiraCode Nerd Font Mono:charset=1f4c1"` (📁) — it should say
`Noto Color Emoji`.

### Updating herdr

`herdr update` refuses to run from inside a herdr pane, and with
`terminal.shell = herdr` every Alacritty window *is* one. Run `herdr-update`
(from `bin/`, on `~/.local/bin`) instead. It strips the `HERDR_*` variables the
guard looks at, updates with `--handoff` so the running server hands its live
panes to the new binary (nothing is killed, not even a `claude` session doing
the update), then reinstalls the agent hooks herdr asks for and prints
`herdr status`. `herdr-update --check` only compares versions. The `update`
shell function (zsh/.zshrc) runs it last, after the package manager, a
`git pull` of this repo (which re-runs `install.sh` when it brings new
commits, so the machine converges on the repo), `oh-my-posh upgrade`, a
`git pull` of each zsh plugin, `yazi-update` and `claude update`, so one
command refreshes everything, including the tools the package manager does
not know about.

`clean` is its counterpart. After the package manager's own cleanup (on apt
that also purges `rc` packages, mostly old kernels), it vacuums the journal to
4 weeks, removes unused flatpak runtimes and dangling docker/podman images,
prunes the uv/pip/go/pnpm/npm caches and stale oh-my-posh init scripts, keeps
only the current and previous Claude Code versions, and deletes the `*.old` /
`*.bak` binaries and broken symlinks left in `~/.local/bin`. Two things are
only reported, never removed: Claude project folders whose repo is gone (they
hold the transcripts and memory) and a non-empty trash. It ends with the
space freed.

**Copying out of a full-screen TUI** (claude, vim, k9s) needs one of these: the app
captures the mouse, so dragging selects nothing. Either hold **Shift while dragging**
to bypass mouse reporting, or skip the mouse entirely with `Ctrl+Shift+K`. This is
the single most-forgotten thing in this config, which is why it is written down here.

## Claude Code status line

The three rows under Claude Code's prompt are not a built-in: they come from
`claude/statusline.py`, which Claude Code runs on every refresh with the session
JSON on stdin. It was written on GeekForge (2026-09-10) and moved here on
2026-09-21 so every machine shows the same thing.

| Row | Contents |
| :--- | :--- |
| 1 | Model, effort level, `[fast/think]` tags, `owner/repo` (or the cwd basename outside a repo), git branch with `+staged ~dirty` or `clean` |
| 2 | Context bar and percentage (green → yellow at 70% → red at 90%), tokens in context / window size, session cost in USD, wall time and API time, `+lines/-lines` when there are edits |
| 3 | Prompt cache (`warm`/`cold`, hit ratio, TTL) and the 5-hour / 7-day rate limits with time to reset |

`install.sh` symlinks the script to `~/.claude/statusline/statusline.py` and, if
`~/.claude/settings.json` has no `statusLine` key yet, adds this one (other keys
are untouched; an existing `statusLine` is never replaced):

```json
"statusLine": {
  "type": "command",
  "command": "/home/<user>/.claude/statusline/statusline.py",
  "padding": 0,
  "refreshInterval": 60
}
```

Notes:

- Needs `python3` only — no packages. `git status` is cached for 5 s in
  `/tmp/claude-1000/statusline-git.cache` because it is slow on big repos.
- Secondary text uses plain white (`\033[37m`), not ANSI dim: dim is nearly
  invisible on the dark theme. Bump to `\033[97m` if it still reads too faint.
- To try a change without a live session, feed it a saved payload:
  `./claude/statusline.py < payload.json`. To capture one, point `statusLine.command`
  at a wrapper like `tee /tmp/payload.json | ~/.claude/statusline/statusline.py`
  for a session, then switch it back.
- Row 2's token count is what the conversation occupies *now*, not the session
  total. Row 3's segments appear only when the payload carries them (older
  Claude Code versions send no `prompt_cache` or `rate_limits`).

## Design notes

- **Portable core, local overrides.** `~/.zshrc` is identical on every machine.
  Anything machine-specific (nvm, PlatformIO, work PATHs, extra aliases) lives in
  `~/.zshrc.local`, which is sourced last and never committed.
- **Guards everywhere.** Every tool integration (`oh-my-posh`, `fzf`, `kubectl`,
  plugins) is wrapped in existence checks, so the same zshrc works on a minimal
  server and a full workstation.
- **Platform-neutral package aliases.** `pkgi` / `pkgu` / `pkgr` / `pkgs` map to
  `dnf` on Fedora and `apt` on Debian/Ubuntu.
- **Probe, don't assume.** The zshrc tests for a tool instead of branching on the
  OS: `ports` uses `ss` where present, else `lsof`.
- **Nerd Font required for the prompt glyphs.** Everything expects *FiraCode Nerd
  Font Mono*. Grab it from [nerdfonts.com](https://www.nerdfonts.com/) if the
  prompt shows broken symbols.

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
