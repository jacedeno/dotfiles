# machines

Per-machine notes. The dotfiles themselves stay portable — `~/.zshrc` is byte-identical
everywhere and anything machine-specific belongs in `~/.zshrc.local`, which is never
committed. This folder is for the things a dotfile *cannot* carry: hardware quirks,
firmware, driver workarounds and the tuning that only makes sense on one box.

Nothing here is installed or symlinked by `install.sh`. It is documentation.

| Machine | File | What it is |
| :--- | :--- | :--- |
| `gimble` | [gimble.md](gimble.md) | Google "Gimble" Chromebook reflashed with MrChromebox, running Fedora |

## When to add a machine here

Add a file when a box needs something the portable config deliberately does not do —
a kernel workaround, a hwdb override, a firmware quirk, a driver that needs pinning.
If it fits in `~/.zshrc.local`, it does not need a page.

Record **why**, not just what. The value of these pages is six months later, when the
symptom comes back and nobody remembers which knob was turned or what was already
ruled out.
