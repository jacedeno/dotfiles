# ThinkPadT470 — personal work laptop, Fedora

A Lenovo ThinkPad T470 running plain Fedora, used as a personal (not
company-issued) work laptop. Unlike the `vscode-remote-work-pc.md` scenario in
`geeklab-infra`, this machine is fully open to installing software — no
corporate IT restrictions.

## Hardware / software

| | |
| :--- | :--- |
| Hostname | `ThinkPadT470` |
| OS | Fedora Linux 44 (Workstation Edition) |
| Kernel | 7.1.5-201.fc44.x86_64 |
| GPU | Intel HD Graphics 520 (Skylake-U GT2) — integrated only |
| zsh | 5.9 |
| Oh My Posh | 29.6.1 |
| herdr | 0.8.0 |
| Claude Code | 2.1.222 |
| Antigravity CLI (`agy`) | 1.1.10 |

## Dotfiles state

| Path | Points to |
| :--- | :--- |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.gitconfig` | `git/.gitconfig` |
| `~/.config/wezterm/wezterm.lua` | `wezterm/wezterm.lua` (kept installed, not the default terminal — see below) |
| `~/.config/alacritty/alacritty.toml` | `alacritty/alacritty.toml` |
| `~/.local/bin/clip2forge` | `bin/clip2forge` |
| `~/.local/bin/mount-excemca` | `bin/mount-excemca` |

`~/.config/ohmyposh/atomic.omp.json` is a copy (vendored by `install.sh`), same
as every other machine.

## Terminal: WezTerm → Alacritty + herdr (2026-08-04)

This is the first machine running **Alacritty** instead of WezTerm as the
default terminal emulator, paired with **herdr** as the local session/pane
manager — the same swap already made for GeekForge's browser terminal (tmux →
herdr, see `geeklab-infra/docs/geekforge-herdr-terminal.md`), just applied
locally instead of remotely.

- **Why Alacritty has no split/tab keybindings ported from wezterm.lua**:
  Alacritty has no built-in multiplexing at all (no tabs, no panes) — that gap
  is exactly what herdr fills. `alacritty/alacritty.toml` sets
  `terminal.shell = { program = "herdr" }`, so every new Alacritty window
  attaches straight to herdr's persistent local session instead of a bare
  shell. Splits, tabs, and detach (`ctrl+b q`) are herdr's own bindings, not
  Alacritty's — mirrored from how ttyd launches the herdr client on GeekForge.
- **Verified 2026-08-04**: launched Alacritty standalone, confirmed no startup
  errors and `herdr status` flipped from `not running` to `running`
  (auto-started). Closing the Alacritty window left the herdr-managed zsh
  process alive — correct persistence behavior, not a leak.
- **herdr agent integrations** (`herdr integration install claude` and
  `herdr integration install antigravity-cli`) were already installed on this
  machine before the terminal swap — hooks at
  `~/.claude/hooks/herdr-agent-state.sh` and
  `~/.gemini/config/hooks/herdr-agent-state.sh`.
- **WezTerm config stays installed** (still symlinked, `wezconfig` alias still
  works) as a fallback; it is just no longer the terminal actually launched
  day to day. `alacrittyconfig` is the new quick-edit alias.
- **Font/colors ported 1:1 from `wezterm.lua`**: FiraCode Nerd Font Mono
  12pt, Tokyo Night palette with the background forced to pure black
  (`#000000`) like the old terminator/wezterm setup. `Ctrl+Shift+K` is bound
  to Alacritty's `ToggleViMode` as the closest equivalent to wezterm's copy
  mode (keyboard-only selection inside full-screen TUIs like claude/vim/k9s).
- **GPU backend pinning does not port.** `wezterm.lua`'s
  `front_end = "WebGpu"` / `webgpu_power_preference = "HighPerformance"` has
  no Alacritty equivalent — Alacritty always renders via OpenGL and doesn't
  expose adapter selection in config. Moot here anyway: this laptop's Intel
  HD 520 is the only GPU (no discrete adapter to prefer).
