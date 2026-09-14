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

Defaults, verified against the `rc.conf` shipped with ranger 1.9.4.

| Key | Action |
| :--- | :--- |
| arrows or `h j k l` | move; `l` / `Enter` opens, `h` goes up one level |
| `E` | edit the selected file (`nano`, unless `$EDITOR` says otherwise) |
| `i` | selected file full screen, read-only (long markdown) |
| `zh` | toggle hidden files (`.git`, `.env`) |
| `zp` | toggle the preview column |
| `S` | shell in the current directory; `exit` returns to ranger |
| `gh` | jump to `~` |
| `/` then text | search by name in the current directory; `n` / `N` next / previous match |
| `f` then text | jump to the first file matching as you type |
| `Space` | mark a file (repeat on others); `v` marks all, `uv` clears |
| `yy` / `dd` / `pp` | copy / cut / paste the selected or marked files |
| `cw` | rename |
| `dD` | delete (asks for confirmation) |
| `:` | ranger command line (`:mkdir name`, `:touch name`) |
| `!` | run a shell command in the current directory |
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
