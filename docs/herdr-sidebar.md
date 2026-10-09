# herdr-sidebar: a VS Code-style sidebar inside herdr

**On trial since 2026-10-09.** It is in dotfiles so it can be tried on every machine, not
because it has been chosen. yazi (`docs/yazi.md`) is the settled file manager; the sidebar
is the GUI-like alternative: a file tree, project search and git panel docked beside the
herdr panes.

Source: `github.com/alexarthurs/herdr-sidebar` (the plugin manifest is in
`plugins/herdr-sidebar`). Needs herdr 0.8+.

## Keys

The prefix is herdr's `ctrl+b`.

| Key | Action |
| :--- | :--- |
| `ctrl+b` `f` | toggle the sidebar: open at its dock edge, focus it if open, close it if focused |
| `ctrl+b` `F` | quick open: fuzzy file picker |
| `ctrl+b` `d` | sidebar on the Source Control view (stage, commit, branches) |

Not `e`/`p`/`g`, which the sidebar's own README suggests: herdr already binds `prefix+e`
(edit scrollback), `prefix+p` (previous tab) and `prefix+g` (goto), and
`herdr config check` does not report the clash.

Inside the sidebar, the gear icon opens its settings (dock edge, unified or separate git
panel, icon theme). They persist across restarts.

## How it gets onto a machine

`install.sh`, wherever herdr is installed: it installs the plugin (a prebuilt,
SHA-256-verified binary where upstream ships one, otherwise a source build that needs
Rust) and appends the three keys above to `~/.config/herdr/config.toml` once. `update` re-runs `install.sh` when a dotfiles pull
brings new commits, so existing machines pick it up on their next `update`.

The plugin updates itself: its own "Update sidebar" action installs the latest stable
release.

## What to know while trying it

- It hooks herdr's focus events (pane, tab, workspace), so it keeps a sidebar docked in
  every tab once opened. That is the design, not a bug.
- The commit-message button drafts messages with the local `claude` CLI.
- It is big (~33k lines of Rust) next to herdr-yazi (a manifest and a 25-line script).

## Removing it

```sh
herdr plugin uninstall herdr-sidebar
```

Then delete the `herdr-sidebar keys` block from `~/.config/herdr/config.toml`,
`herdr server reload-config`, and drop section 4b from `install.sh` (otherwise the next
`install.sh` run puts it back).
