# ThinkPadT470 — personal work laptop, Fedora

A Lenovo ThinkPad T470 running plain Fedora, used as a personal (not
company-issued) work laptop. Unlike the `vscode-remote-work-pc.md` scenario in
`geeklab-infra`, this machine is fully open to installing software — no
corporate IT restrictions.

## Hardware / software

| | |
| :--- | :--- |
| Hostname | `ThinkPadT470` |
| OS | Fedora Linux 45 (Workstation Edition) — pre-release install, then cloned from BD-1 on 2026-10-22 |
| Kernel | 7.2.11-300.fc45.x86_64 |
| GPU | Intel HD Graphics 520 (Skylake-U GT2) **plus an NVIDIA GeForce 940MX** (GM108M, Maxwell, `10de:134d`), Optimus |
| NVIDIA driver | RPM Fusion **`580xx`** legacy branch (580.178.04). The current branch (615+) dropped Maxwell |
| Login user | `cedenoj` |
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
- **Font/colors were ported 1:1 from the old `wezterm.lua`**: FiraCode Nerd
  Font Mono 12pt, Tokyo Night palette with the background forced to pure black
  (`#000000`) like the old terminator/wezterm setup. `Ctrl+Shift+K` is bound
  to Alacritty's `ToggleViMode` as the closest equivalent to wezterm's copy
  mode (keyboard-only selection inside full-screen TUIs like claude/vim/k9s).
  `alacrittyconfig` is the quick-edit alias.
- **GPU backend pinning did not port.** The old `wezterm.lua` set
  `front_end = "WebGpu"` / `webgpu_power_preference = "HighPerformance"`, which
  has no Alacritty equivalent — Alacritty always renders via OpenGL and doesn't
  expose adapter selection in config. The laptop does have a discrete
  GeForce 940MX next to the Intel HD 520 (an earlier version of this note
  said integrated-only, which was wrong), but Alacritty renders on the Intel
  GPU like the rest of the desktop.

### Bug hit right after reboot: Alacritty wouldn't open from the GNOME app grid

**Symptom**: launching Alacritty from an already-open terminal worked fine;
launching it by clicking its icon in GNOME did nothing — the window never
appeared.

**Root cause** (confirmed via `journalctl --user -b 0 | grep -i alacritty`):

```
Alacritty.desktop[2638]: Error: Custom { kind: NotFound, error: "Failed to
spawn command 'herdr': No such file or directory (os error 2)" }
```

Apps launched by GNOME Shell run as `app-gnome-*.scope` units under the
**systemd `--user` manager**, not as children of a login shell — so they
never source `~/.zshrc` and never see its `PATH="$HOME/.local/bin:...:$PATH"`.
Confirmed directly: `systemctl --user show-environment | grep PATH` showed
`/usr/lib64/ccache:/usr/local/bin:/usr/bin:/var/lib/snapd/snap/bin` — no
`~/.local/bin`, where `herdr` lives. An interactive shell's `PATH` (via
`zsh -lc 'echo $PATH'`) had it fine, which is exactly why the terminal-launched
test earlier that day looked like it worked and gave a false sense that the
config was done.

**Fix**: `environment.d/10-local-bin.conf` (new in this repo, linked by
`install.sh` when `systemctl` is present) — a
[`~/.config/environment.d/`](https://www.freedesktop.org/software/systemd/man/latest/environment.d.html)
drop-in setting `PATH=${HOME}/.local/bin:${HOME}/bin:${PATH}` for the systemd
user manager, so every GUI-launched app (not just Alacritty — anything
dbus-activated or `.desktop`-launched) picks up `~/.local/bin`. Takes effect
on the **next login** (`systemd-environment-d-generator` runs at manager
startup, not on `daemon-reload`).

**Verified live without waiting for a relogin**: `systemctl --user
set-environment PATH=...` followed by `gio launch
/usr/share/applications/Alacritty.desktop` immediately spawned a working
Alacritty with `herdr` attached (confirmed via `herdr status` going
`running` and `pgrep -af herdr` showing the client + server). This GNOME's
app-scope launch model queries the systemd user manager's *current*
environment per launch rather than inheriting a stale copy from gnome-shell's
own startup — useful for testing an environment.d change without a full
logout, but the drop-in file is still what makes it durable across reboots.

## Cloned from BD-1 (2026-10-22)

Rebuilt to match BD-1 with the Keychain USB kit
(`geeklab-infra/provisioning/fedora-clone/`, doc `docs/fedora-clone-usb.md`):
BD-1's packages, flatpaks, GNOME settings and extensions, dotfiles and VS Code
extensions. The run surfaced the 940MX. BD-1's NVIDIA packages (615 branch)
do not support Maxwell, so the driver was swapped for `akmod-nvidia-580xx` +
`xorg-x11-drv-nvidia-580xx-cuda`. After the reboot, `nvidia-smi` reports the
940MX on 580.178.04. `restore.sh` now picks the 580xx branch by itself on
GM/GP/GV GPUs.

The pre-clone state (dconf dump, RPM and flatpak lists) is kept in
`~/pre-restore-backup/` on the laptop.

## The bench laptop at the office (2026-11-02)

BD-1 is being sold, so the T470 takes over as the bench machine: it stays on at
the office, on GeekSpot's WiFi, next to the sniffer and the bench units.

### WireGuard: `wg0` peer "ThinkPadT470", `10.0.0.6`

- **The old key was gone.** The clone from BD-1 left `/etc/wireguard` empty and
  no WireGuard profile in NetworkManager, and WG-Dashboard never stored the
  private key of this imported peer. A new key pair was generated on the
  laptop, and the peer's public key was swapped on CT 104, keeping its name and
  address (`geeklab-infra/docs/wireguard-lxc-104.md`, "Changing an imported
  peer's public key").
- **A NetworkManager profile named `GeekLab`**, as on Jose's other PCs, with
  the interface of the same name, in GNOME's menu. System-wide
  (`connection.permissions` empty), `autoconnect yes` and
  `autoconnect-retries 0` (retry forever), so it is up at boot before anyone
  logs in. The private key lives only in
  `/etc/NetworkManager/system-connections/GeekLab.nmconnection` (root, 0600).
  - Address `10.0.0.6/32`, endpoint `vpn.geekendzone.net:51820`, keepalive
    25 s, MTU 1380 (the uplink is GeekSpot's LTE).
  - **Split tunnel:** peer allowed IPs `10.0.0.0/24, 192.168.68.0/24,
    192.168.30.0/24`, routed by `wireguard.peer-routes`. CT 104 does not NAT
    toward `wg0`, so the house subnets must be listed for GeekForge (`.68`) and
    C2-B5 (VLAN 30) to get answers. The laptop's internet stays on GeekSpot,
    so a dead tunnel never takes its DNS with it.
  - **Switching it off in GNOME's menu keeps it off until it is switched on
    again or the laptop reboots. That is Jose's choice** (2026-11-02): on by
    default, and a manual off is respected. Remotely, bring it back with
    `ssh -J root@10.80.0.5 cedenoj@<GeekSpot address> sudo nmcli connection up GeekLab`.
  - **Tried and undone the same day:** a `wg-quick@GeekLab` unit with the
    interface unmanaged by NetworkManager, which hid it from GNOME's menu.
    Jose wanted the button back. Before that, a `wg-quick@wg0` that NM had
    adopted lost `10.0.0.6` and its routes to a menu click while the
    handshake carried on (the peer looked alive on CT 104 and nothing
    answered), so never let NM and wg-quick share the interface. The switch
    scripts are `/usr/local/sbin/geeklab-switch.sh` and `geeklab-to-nm.sh`.
- **Endpoint re-resolve:** `wg-reresolve-dns@GeekLab.timer` runs every 2
  minutes `/usr/local/sbin/wg-reresolve-dns.sh
  /etc/wireguard-reresolve/GeekLab.conf`, a copy of wireguard-tools'
  `contrib/reresolve-dns` fed a file with only the peer's public key and
  endpoint (no private key). It sets the endpoint again from the hostname when
  the last handshake is older than 135 s, so the tunnel follows a change of the
  house WAN (WireGuard resolves the name only once on its own). While the
  laptop has no internet it fails every 2 minutes ("Name or service not
  known"); that is the symptom, not the cause.
- **WiFi power save is off** (`/etc/NetworkManager/conf.d/80-wifi-powersave-off.conf`,
  `wifi.powersave = 2`). On 2026-11-02 10:27 the laptop stayed associated to
  GeekSpot (−45 dBm) but sent nothing for minutes, NM reported
  `CONNECTED_SITE`, and only a reboot brought it back. No `iwlwifi` error was
  logged and GeekSpot's LTE was up the whole time. Power save on the Intel
  8260 is the usual suspect, and the bench runs on AC anyway. If it happens
  again, the cause is something else.
- **firewalld:** `GeekLab` is in the default `FedoraWorkstation` zone, which
  allows SSH.
- **From GeekForge:** `ssh t470` (`10.0.0.6`, user `cedenoj`, GeekForge's key
  in `authorized_keys`). The host key is the same as over GeekSpot.
- **Fallback through GeekSpot:** `ssh -J root@10.80.0.5 cedenoj@<address>`.
  The MAC is stable per SSID (Fedora's `wifi.cloned-mac-address=stable-ssid`),
  so `GeekSpot` and `GeekSpot5G` give it two different addresses
  (`192.168.8.199` and `.186` on 2026-11-02). GeekSpot's `/tmp/dhcp.leases`
  lists it as `ThinkPadT470`.

### Staying on

- **On AC it never suspends:** GNOME's `sleep-inactive-ac-type` is `nothing`
  for `cedenoj`, and also for the login screen
  (`/etc/dconf/db/gdm.d/95-bench-power`, then `dconf update`).
- **Lid closed on AC:** ignored
  (`/etc/systemd/logind.conf.d/50-bench-lid.conf`,
  `HandleLidSwitchExternalPower=ignore`).
- **On battery nothing changed:** idle and the lid still suspend it, so it has
  to stay plugged in to be reachable.

### Trimmed for the old CPU (2026-11-02)

An i7-6600U (2 cores, 4 threads, 2016) with 32 GB: memory is plenty, CPU is
not. Snapper snapshot **#283** ("before bench cleanup") was taken first.

- **Removed, 227 packages** (`dnf remove --no-autoremove`, then only the
  leftovers that clearly came with them):
  - Cloudflare WARP, Docker (`docker-ce` and plugins, `/var/lib/docker`, the
    `docker` group), libvirt with GNOME Boxes and virt-manager, QEMU;
  - the NVIDIA 580xx driver (Jose's call: the bench needs no dGPU). The kernel
    arguments that blacklisted nouveau and the hand-made
    `/etc/modprobe.d/blacklist-nouveau.conf` (kept as
    `/root/blacklist-nouveau.conf.removed-20261102`) went with it, and the
    initramfs was rebuilt. nouveau now runtime-suspends the 940MX when idle;
  - the VM guest agents (QEMU, VMware, VirtualBox, SPICE), the live-image
    services, iSCSI, Stratis, sssd, ModemManager (no modem), abrt and its
    libreport plugins, the Anaconda installer, `ibus-typing-booster`, sysstat.
  - **Not autoremoved:** dnf5 offered 288 more "unused" packages, among them
    `gdb`, `patch`, `wl-clipboard`, emoji fonts, `dnf-plugins-core` and
    `cryptsetup`. `libreport-filesystem` stays because `mdadm` (and through it
    `udisks2` and GNOME) needs it.
- **Off in the background:** `gnome-software` (masked user service, no
  automatic downloads) and with it PackageKit and `dnf5daemon`;
  `dnf-makecache.timer`; `localsearch-3` (masked, index erased); `mdmonitor`,
  `raid-check.timer` and `lvm2-monitor` (no RAID, no LVM). Updates are manual:
  `sudo dnf upgrade`.
- **Kept:** `evolution-data-server` (gnome-shell requires it), Podman (the
  geekvibe gateway tests run in it), snapper.
- **GNOME:** animations off; power profile `performance` (tuned
  `throughput-performance`).

| | Before | After |
| :--- | ---: | ---: |
| Boot (`systemd-analyze`) | 57.3 s | 39.2 s |
| Userspace | 21.6 s | 10.3 s |
| RAM used at idle | 2231 MB | 1539 MB |
| Enabled system services | 69 | 42 |
| Processes | 289 | 263 |

Measured "before" at 31 minutes of uptime and "after" at 4 minutes, so the
after figures are if anything high.

### Claude Code (2026-11-02)

Native installer (`~/.local/bin/claude`, 2.1.316) and `uv` 0.13.6.

- **Skills (46):** `claude-code-skills` copied from GeekForge to
  `~/repos/claude-code-skills` and `install.sh` run; GeekForge's skills that
  are not in that installer (superpowers, archify, heygen and others) copied
  over with `~/.agents/skills`. The "PromptScript does not support global
  skill installation" failures in its log concern another agent, not Claude
  Code.
- **Settings:** `install-settings.sh` (Concise, the status line), plus
  `attribution` empty for commits and PRs, as on GeekForge (the repo's
  `preferences.json` does not carry it).
- **MCP servers, as on GeekForge** (Jose's call: the office is safe for
  them): `grafana` (`grafana.excemca.com`) and `grafana-iot`
  (`192.168.68.150:3000`, over `GeekLab`) with their tokens in
  `~/.grafana-mcp-token` and `~/.grafana-iot-mcp-token`; `google-workspace`
  with `~/.config/geekendzone/google-workspace.env` and its OAuth state
  (`~/.google_workspace_mcp`, `~/.workspace-mcp`) copied from GeekForge; `rea`.
  The claude.ai connectors come with the claude.ai login.

### Terminal, dock and desktop, as on BD-1 (2026-11-02)

Copied from BD-1 over the house LAN (`192.168.68.64`). herdr and yazi came from
C2-B5 first, while BD-1 was unreachable.

- **The repo's aliases were already loaded** (51). `~/.zshrc.local` gained
  `claude-yolo`, the PlatformIO and opencode `PATH`s, nvm, and uv's
  `. ~/.local/bin/env`, which uv's installer had appended to the tracked
  `zsh/.zshrc` (reverted there). BD-1's Android lines (`ANDROID_HOME`, the
  `emulator` alias) are left out: no Android Studio here (Jose's call).
- **herdr 0.9.5, herdr-core (`hc`), herdr-app 0.1.11 and yazi 26.9.1** in
  `~/.local/bin` and `~/.local/share/herdr-app`, with herdr-app's `.desktop`
  entry and icon. Alacritty's `terminal.shell = herdr` had nothing to launch
  until then. `install.sh` was run again (herdr-yazi and herdr-sidebar
  plugins and keys, the Dash to Dock style), then `herdr-app-config`.
- **Dock (`favorite-apps`), BD-1's:** Chrome, Files, Alacritty, VS Code, Text
  Editor, WhatsApp Web, Thunderbird, Microsoft Teams, Zoom, Discord, VLC,
  ONLYOFFICE, Settings, Software, Calculator. Left out: Android Studio and
  Cloudflare WARP (both removed from this laptop). The two Chrome web-app
  launchers were copied from BD-1; the apps themselves come with Chrome's
  sync. Outlook's launcher was deleted on both laptops (Jose's call).
- **Desktop:** the GeekendZone wallpaper (`~/.local/share/backgrounds/`,
  `zoom`, also the lock screen); battery percentage hidden.
- **`~/.ssh`:** BD-1's keys (`id_ed25519`, `id_ed25519_github`,
  `id_ed25519_iot-150-root`, `id_ed25519_k3s-master`) and its `config`
  (`github.com` over port 443, `homepage`, `docker`, `geekforge`, `laptop`,
  `octopi`), plus `t470`. **Wipe them from BD-1 before it is sold.** The
  repos under `~/repos` are cloned over SSH with that GitHub key.
- **No Clipboard Indicator:** copied from C2-B5 first, but v71 crashes on
  GNOME Shell 51 (`Clutter.get_default_backend is not a function`) and BD-1
  does not have it, so it was removed. Telegram, herdr-app and KiCad stay
  installed but are not in the dock.

### Bench services (2026-11-02, moved from BD-1)

- **`ctc-watch.timer`** (geekvibe, every 15 min, read-only SSH to the bench
  ACCESS2000 `192.168.8.229:20022`) and **`perma-advert-log.timer`** (auto-lubes,
  hourly, the nRF Sniffer on `/dev/ttyACM0`), as user units in
  `~/.config/systemd/user/`, with `ctc-watch.service.d/until.conf`
  (`CTC_WATCH_UNTIL=2026-11-05T12:00:00Z`). Lingering is on for `cedenoj`.
  Both were disabled on BD-1, and their data (`geekvibe/data/ctc-watch/`,
  `auto-lubes/data/captures/perma-advert-log.csv`) copied over.
- **USB:** `cedenoj` is in `dialout`; `/etc/udev/rules.d/99-platformio-udev.rules`
  (PlatformIO's) and `70-nrf-sniffer.rules` (the sniffer's tty, mode 0666, so
  the user timers can open it without a fresh login).
- **Toolchain:** PlatformIO Core 6.2.0 (`~/.platformio/penv`, from
  `get-platformio.py`), the cycle-counter (`m5tough`, `ws5b`) and cycle-pulser
  (`xiao`) builds run once so the platforms are already downloaded; `nrfutil`
  8.2.1 with `ble-sniffer` 0.22.0; `uv` with `bleak` cached for
  `gatt_check.py`. The auto-lubes tool tests pass and `ble_scan.py` sees
  adverts through the internal adapter (`34:41:5D:1A:A1:11`).
- **`gh`:** the token is stored in GNOME's keyring, which autologin leaves
  locked, so it is lost on every reboot. Log in with
  `gh auth login --insecure-storage`. Git itself uses BD-1's GitHub SSH key.
