# Browsing files as a hierarchy in the terminal: `tree` and `yazi`

Two tools, two jobs. `tree` prints the directory hierarchy (the VSCode explorer, static).
`yazi` walks it: three columns (parent, current, preview of the selected file), previews
markdown, code and archives in place, and hands the file to `$EDITOR` (`nano`) when you
want to edit. Both are installed by `install.sh` on Fedora and Debian/Ubuntu. On Windows
they live in WSL.

History: ranger was the walker from 2026-09-13 to 2026-10-09. Yazi replaced it: same vim
keys and three columns, but asynchronous (no freezes on big folders or slow SMB/NFS
mounts), built-in previews, and deletes go to the trash. Tried and discarded on
2026-09-13: `nnn`, `mc`, `broot`, `eza`.

## tree

```bash
tree -L 2 -I .git      # two levels deep, skip .git
tree -d -I .git        # directories only
tree -a -I .git        # include dotfiles
```

Without `-I .git` the `.git` internals flood the output. `-L` keeps it readable in big
repos. The last line is the count (`11 directories, 17 files`). Handy for pasting a repo
layout into a README or a commit message.

## yazi

```bash
cd ~/repos/some-repo && yazi
```

Inside herdr there is a shortcut: `ctrl+b` then `y` opens yazi in a split pane, in the
current pane's folder (`ctrl+b` then `Y` for a new tab). That comes from the herdr-yazi
plugin, which `install.sh` adds on every machine where herdr is installed, together with
those two keys (appended once to `~/.config/herdr/config.toml`; the rest of that file
stays per machine).

### Keys

Defaults, verified against `keymap-default.toml` shipped with yazi 26.9.1. `~` (or `F1`)
inside yazi lists every key.

**Move around**

| Key | Action |
| :--- | :--- |
| arrows or `h j k l` | move; `l` enters a folder, `h` goes up one level |
| `gg` / `G` | top / bottom of the list |
| `gh` | jump to `~` |
| `.` | show or hide hidden files (`.git`, `.env`) |
| `J` / `K` | scroll the preview down / up (long markdown) |

**Create, open, rename**

| Key | Action |
| :--- | :--- |
| `a` | create: type `notas.md` for a file, `borradores/` (trailing slash) for a folder |
| `Enter` or `o` | open: text files go to `$EDITOR` (`nano`; `Ctrl+O` saves, `Ctrl+X` returns) |
| `r` | rename; with several files selected, renames them all in the editor |

**Copy, move, delete**

| Key | Action |
| :--- | :--- |
| `y` | copy the selected (or hovered) files |
| `x` | cut. It does not delete: it prepares the files to be moved |
| `p` | paste into the folder you are in (`P` overwrites existing files) |
| `d` | move to the trash. Asks to confirm. `gt` browses the trash |
| `D` | delete permanently. No trash: it is gone |

**Several files at once**

| Key | Action |
| :--- | :--- |
| `Space` | select the file under the cursor and move down; then `y`, `x`, `d` act on all |
| `Ctrl+A` | select every file in the folder |
| `v` | visual mode: move to select a range |
| `Esc` | clear the selection |

**Search**

| Key | Action |
| :--- | :--- |
| `/` | find by name in the current folder; `n` next match, `N` previous |
| `f` | filter the list as you type |
| `S` | search file contents below here (ripgrep) |
| `z` | jump anywhere below here with `fzf` |

`s` (search by name recursively) needs `fd`, which is not installed. `Z` needs `zoxide`,
also not installed.

**Shell and misc**

| Key | Action |
| :--- | :--- |
| `;` | run one shell command here, without leaving yazi |
| `Ctrl+Z` | suspend yazi to the shell; `fg` brings it back |
| `cc` | copy the file's full path to the clipboard |
| `q` | quit |

### Notes

- No config in this repo: yazi runs on its defaults, so there is nothing to link.
- ranger had one override, `set vcs_aware true` (git status next to each file). Yazi has no
  built-in equivalent; the official `git.yazi` plugin adds it
  (`ya pkg add yazi-rs/plugins:git` plus a few lines of `init.lua`). Not installed: kept
  simple until it is missed.
- Images: the preview column shows text, code, archives and folders. Real image previews
  need a terminal with the Kitty graphics protocol; Alacritty has none, so images do not
  render on any machine here. herdr itself would pass them through.
- Updating: `update` runs `bin/yazi-update`, which upgrades `~/.local/bin/yazi` to the
  latest release when there is one (`yazi-update --check` only compares).

## Rolling it out to another machine

`update` does it. Its first step after the system packages is a `git pull` of this repo;
when the pull brings new commits it re-runs `install.sh`, which on a machine set up
before 2026-10-09:

1. installs yazi into `~/.local/bin` and links `yazi-update`;
2. removes the `ranger` package and its dangling `~/.config/ranger/rc.conf` symlink
   (`~/.local/share/ranger`, bookmarks, is left alone);
3. where herdr runs, installs the herdr-yazi plugin and appends its two keys.

`tree` was already there. Without `update`: `git -C ~/repos/dotfiles pull && ~/repos/dotfiles/install.sh`.
