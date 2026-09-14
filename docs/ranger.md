# Browsing files as a hierarchy in the terminal: `tree` and `ranger`

Two tools, two jobs. `tree` prints the directory hierarchy (the VSCode explorer, static).
`ranger` walks it: three columns (parent, current, preview of the selected file), previews
markdown and code in place, and hands the file to `nano` when you want to edit. Both are
installed by `install.sh` on Fedora and Debian/Ubuntu. On Windows they live in WSL.

Tried and discarded on 2026-09-13: `nnn`, `mc`, `broot`, `eza`. None added anything worth a
third tool; fuzzy search is already covered by `fzf`.

## tree

```bash
tree -L 2 -I .git      # two levels deep, skip .git
tree -d -I .git        # directories only
tree -a -I .git        # include dotfiles
```

Without `-I .git` the `.git` internals flood the output. `-L` keeps it readable in big
repos. The last line is the count (`11 directories, 17 files`). Handy for pasting a repo
layout into a README or a commit message.

## ranger

```bash
cd ~/repos/some-repo && ranger
```

It needs the whole screen: leave Claude Code first (`/exit`), or open a second herdr pane.

### Keys

Defaults, verified against the `rc.conf` and `commands.py` shipped with ranger 1.9.4.
Commands that start with `:` are typed into ranger's own command line: press `:`, type
the rest, press `Enter`.

**Move around**

| Key | Action |
| :--- | :--- |
| arrows or `h j k l` | move; `l` / `Enter` opens the folder or file, `h` goes up one level |
| `gh` | jump to `~` |
| `zh` | show or hide hidden files (`.git`, `.env`) |
| `zp` | show or hide the preview column |
| `i` | selected file full screen, read-only (long markdown); `q` comes back |

**Create**

| Key | Action |
| :--- | :--- |
| `:touch notas.md` | new empty file in the current folder |
| `:mkdir borradores` | new folder |
| `:edit notas.md` | new file opened straight in `nano`; it is created when you save |

**Edit**

| Key | Action |
| :--- | :--- |
| `E` | edit the selected file in `nano` (`Ctrl+O` saves, `Ctrl+X` returns to ranger) |
| `cw` | rename |

**Copy, move, delete**

| Key | Action |
| :--- | :--- |
| `yy` | copy the selected (or marked) files |
| `dd` | cut. It does not delete: it prepares the files to be moved |
| `pp` | paste what was copied or cut, into the folder you are in |
| `dD` | delete. Asks `y`/`n`. No trash: it is gone. On a folder, deletes everything inside |

**Several files at once**

| Key | Action |
| :--- | :--- |
| `Space` | mark the file under the cursor (repeat on each one); then `yy`, `dd` or `dD` act on all marked |
| `v` | mark every file in the folder |
| `uv` | clear all marks |

**Search**

| Key | Action |
| :--- | :--- |
| `/text` | search by name in the current folder; `n` next match, `N` previous |
| `f` then text | jump to the first file that matches as you type |

**Shell and misc**

| Key | Action |
| :--- | :--- |
| `S` | open a shell in the current folder; `exit` returns to ranger |
| `!` then a command | run one shell command here, without leaving ranger |
| `Ctrl+R` | reset and redraw if the screen gets garbled |
| `q` | quit |

### Editing

`E` opens the file in `nano`: write, `Ctrl+O` saves, `Ctrl+X` exits back to ranger.
`Enter` on a text file ends up in `nano` too, but ranger picks the program by file type,
so `E` is the predictable choice. Set `EDITOR` in `~/.zshrc.local` to change it.

### Notes

- Python-based, so it takes a moment to start. Fine on every machine here.
- `ranger --copy-config=rc` writes an editable `~/.config/ranger/rc.conf` if you ever
  want custom keys. Not done anywhere yet; the defaults are enough.
