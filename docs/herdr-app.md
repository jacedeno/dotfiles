# herdr-app (GUI)

[herdr-app](https://herdr.dev) is the desktop GUI for herdr, built on herdr-core (`hc`).
It runs alongside the herdr TUI; it does not replace it. First installed on C2-B5 on
2026-11-01 (herdr-app 0.1.11).

The herdr TUI's `config.toml` does not carry over: herdr-app keeps its config in
`~/.config/herdr-app/` and binds keys in a different model. This directory holds the
pieces that were migrated, and `bin/herdr-app-config` applies them.

## What is in `herdr-app/`

| File | Purpose |
|---|---|
| `keys.json` | Only the four launcher keys. Merged into the app's own `keys.json`, which herdr-app writes full of defaults |
| `settings.json` | `appearance: dark`, `theme: gruvbox`. Merged the same way |
| `themes/gruvbox.json` | gruvbox dark, the theme the herdr TUI used |
| `mods/yazi-split/` | Opens yazi in a split to the right |
| `mods/yazi-tab/` | Opens yazi in a new tab |
| `mods/panel-files/` | Toggles the right panel on the Files view |
| `mods/panel-changes/` | Toggles the right panel on the Changes (git) view |

## Keys

| Key | herdr TUI equivalent | Action |
|---|---|---|
| `ctrl-shift-y` | `prefix+y` (herdr-yazi) | yazi in a split |
| `ctrl-alt-y` | `prefix+Y` (herdr-yazi) | yazi in a new tab |
| `ctrl-shift-f` | `prefix+f` (herdr-sidebar) | toggle the Files panel |
| `ctrl-shift-d` | `prefix+d` (herdr-sidebar) | toggle the Changes panel |

`prefix+shift+f` (herdr-sidebar quick open) was not migrated: herdr-app has no
equivalent. The command palette (`ctrl-shift-p`) and the picker (`ctrl-shift-k`) cover
most of it.

## Why the keys open mods

herdr-app has no prefix chords, and a key action is a single string: one command plus
at most its first argument (`pane.split:right`). Opening yazi in a split needs two
arguments (direction and argv), and toggling a panel needs logic. So each key runs
`mod.open:<name>`, which opens a tiny invisible overlay mod. The mod does the job in
`init()` and closes itself.

A mod checks `props().overlay` first and does nothing without one. That way
`herdr-app check <mod>` loads it without touching the live window.

## Applying it

`install.sh` links `bin/herdr-app-config` into `~/.local/bin` and runs it when
`~/.config/herdr-app` exists. Start herdr-app once before that, because it writes its
config directory on first launch. By hand:

```bash
herdr-app-config
```

What it does:

- **Merges** `keys.json` and `settings.json`: only the keys listed here change, and
  everything else is kept.
- **Copies** the four mods and the theme.
- **Runs** `herdr-app check` on each mod.

It is idempotent and backs up both JSON files to `~/.dotfiles-backup/herdr-app-<timestamp>/`
first.

**A click in the theme picker wins over `settings.json`.** The UI stores it in
`layouts/.state/main.json`. That is why the script also runs
`herdr-app do app.theme --name gruvbox`, which only takes effect while a window is
open. If the theme does not change, pick gruvbox once in Settings.

## Gotchas

- **Launch it from the app menu or with `gtk-launch herdr-app`,** not from a terminal.
  `^C` in that terminal closes the window.
- **Never paste an agent prompt into the shell.** The herdr-app onboarding prompt
  ``read `herdr-app --skill`, then …`` is meant for an agent. In zsh, `read` takes
  every word of the skill as a variable name. One of those words is `path`, which zsh
  ties to `$PATH`, so PATH ends up empty. The herdr server keeps that pane's shell
  alive, so restarting the terminal does not fix it, and `exec zsh` inherits the
  empty PATH. The fix, in that pane:

  ```bash
  export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin && exec /usr/bin/zsh
  ```

- **Useful commands:** `herdr-app status`, `herdr-app ls`, `herdr-app do <command>`,
  `herdr-app shot` (screenshot), `herdr-app commands`. Run `herdr-app --skill` for the
  full reference.
