# gimble — Santi's laptop (Chromebook running Fedora)

**This is Santi's laptop, and it is in daily use.** "gimble" is only the board name
from DMI (`Google` / `Gimble`). The machine itself has the default hostname `fedora`
and the single user `santi`, and on the network it is the reservation
**`Santi - Laptop`** (`192.168.68.45`). On 2026-10-10 this note was deleted as
"no longer in use", because nobody recognised the name. It was restored on
2026-10-11. Network, access and the MAC trap are in `geeklab-infra`:
`docs/santi-laptop.md`.

**This is not a normal laptop.** It is a Google "Gimble" Chromebook (Alder Lake,
`Google_Brya` family) whose stock ChromeOS firmware was replaced with
**MrChromebox coreboot UEFI**, now running plain Fedora. Most "my laptop does X"
advice does not apply, because the hardware talks through the ChromeOS Embedded
Controller (EC) rather than the usual ACPI paths.

Read that first — it explains nearly every oddity below.

## Hardware

| | |
| :--- | :--- |
| Model | Google Gimble rev3 (`Google_Brya`), convertible |
| Firmware | coreboot / **MrChromebox-2603.2** (05/17/2026) |
| CPU | Intel Core i3-1215U (Alder Lake-UP3) — 6 cores / 8 threads, 0.4–4.4 GHz |
| RAM | **7.6 GiB LPDDR4-4267, soldered** (not upgradeable) |
| GPU | Intel UHD Graphics (Alder Lake-UP3 GT1) — integrated only, no discrete |
| Storage | KIOXIA BG5 238 GB NVMe (**DRAM-less**) |
| Display | 1920×1200 eDP, touchscreen + stylus |
| Touchpad | Elan `ELAN0000` over I²C (`elan_i2c`, `i2c_designware.5`, IRQ 42) |
| Touchscreen | Elan `ELAN9050` over I²C (`hid-multitouch`) + stylus |
| Wi-Fi / BT | Intel AX211 (CNVi) — **combo chip, shared 2.4 GHz antenna** |
| Audio | SOF `sof-rt5682` + 2× MAX98390 amps |
| Battery | Li-ion, 5095 mAh design / 4521 mAh full (~89 % health), 30 cycles (2026-10-11) |

`dmidecode` reports the RAM as 2× 1 GiB. That is a firmware quirk — trust
`/proc/meminfo` (7.6 GiB), not DMI.

## Software

| | |
| :--- | :--- |
| OS | Fedora 45 (Prerelease) — upgraded from 44 between 2026-09-25 and 2026-10-11 |
| Kernel | 7.2.8-300.fc45.x86_64 (2026-10-11) |
| Desktop | GNOME Shell 51.0 on **Wayland** (2026-10-11) |
| Filesystem | btrfs on `/dev/nvme0n1p3`, subvolumes `root` + `home`; ext4 `/boot`, vfat ESP |
| Swap | zram 7.6 GB (`lzo-rle`) — no disk swap |
| Power | `tuned` + `tuned-ppd` (**not** `power-profiles-daemon`), plus `thermald` |

## Dotfiles state

Everything from this repo is installed and symlinked normally:

| Path | Points to |
| :--- | :--- |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.gitconfig` | `git/.gitconfig` |
| `~/.config/git/hooks` | `git/hooks` |
| `~/.config/alacritty/alacritty.toml` | `alacritty/alacritty.toml` |
| `~/.config/environment.d/10-local-bin.conf` | `environment.d/10-local-bin.conf` |
| `~/.local/bin/clip2forge` | `bin/clip2forge` |
| `~/.local/bin/mount-excemca` | `bin/mount-excemca` |

`~/.config/ohmyposh/atomic.omp.json` is a **copy**, not a symlink — that is by
design, `install.sh` vendors the theme so the prompt works offline.

Versions here (2026-08-07): zsh 5.9, Oh My Posh 29.17.0, Alacritty 0.17.0 (Fedora repos),
herdr 0.8.0.

### `~/.zshrc.local`

Deliberately almost empty. Only one alias:

```zsh
alias claude-yolo="claude --dangerously-skip-permissions"
```

## Terminal: WezTerm → Alacritty + herdr (2026-08-07)

Second machine to make the swap, after `ThinkPadT470`. Same shape: Alacritty as
the emulator with `terminal.shell = herdr`, so every window attaches to herdr's
persistent local session; splits, tabs and detach (`ctrl+b q`) are herdr's
bindings, since Alacritty has no multiplexing of its own. Font and colors come
from `alacritty/alacritty.toml` unchanged (FiraCode Nerd Font Mono 12pt, Tokyo
Night on pure black), and the font was already installed here.

Install was `dnf install alacritty` (0.17.0, in Fedora's repos — no COPR needed,
unlike WezTerm) plus herdr's official installer,
`curl -fsSL https://herdr.dev/install.sh | sh`, into `~/.local/bin`.

**The GNOME `PATH` bug did not happen here, because the fix shipped first.**
`systemctl --user show-environment` on this box showed
`PATH=/usr/local/bin:/usr/bin` — no `~/.local/bin`, exactly the state that made
Alacritty fail to spawn `herdr` from the app grid on the ThinkPad. Re-running
`install.sh` linked `environment.d/10-local-bin.conf` before Alacritty was ever
launched from GNOME, so the bug was skipped rather than rediscovered. The
drop-in takes effect at next login; it was applied live for the test with
`systemctl --user set-environment PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin"`.

**Verified 2026-08-07**: `gio launch /usr/share/applications/Alacritty.desktop`
opened a window with no errors and flipped `herdr status` from stopped to
`server: running` (auto-started). Closing that window left `herdr server` alive
with the client and Alacritty gone — correct persistence, not a leak.

### Default terminal needed a package that was missing

Unlike the ThinkPad, this machine also made Alacritty GNOME's **default**
terminal — which turned out to need more than a config file:

- `org.gnome.desktop.default-applications.terminal exec` was already
  `xdg-terminal-exec` (GNOME 50's default), **but the binary did not exist** —
  nothing on the system provided it. So the setting pointed at a missing
  program, and "Open in Terminal" had nothing well-defined to launch.
- Fix: `dnf install xdg-terminal-exec` (0.14.1) and write
  `~/.config/xdg-terminals.list` containing `Alacritty.desktop`.

That list file is the spec-compliant lever, not the deprecated gsettings key —
leave `exec` pointing at `xdg-terminal-exec` and change the list instead.
Confirmed by running `xdg-terminal-exec`, which spawned Alacritty.

`~/.config/xdg-terminals.list` is hand-written and **not** managed by
`install.sh` — it is a per-machine preference, like everything else in this
folder. To point the default at a different emulator, put its `.desktop` file
name in that list instead. `alacrittyconfig` is the quick-edit alias for the
current config.

### herdr agent integrations

Installed the same day, both fresh on this machine:

```bash
herdr integration install claude            # ~/.claude/hooks/herdr-agent-state.sh
herdr integration install antigravity-cli   # ~/.gemini/config/hooks/herdr-agent-state.sh
```

Each also registers itself in the agent's own settings (`~/.claude/settings.json`,
`~/.gemini/config/hooks.json`), which is what lets herdr show per-pane agent
state. Reversible with `herdr integration uninstall <name>`.

## System tweaks applied

Applied 2026-07-25 while chasing touchpad lag and general sluggishness. None of
these are managed by `install.sh` — they are hand-placed system files.

| Change | Where | Why |
| :--- | :--- | :--- |
| `battery_detection=false` | `/etc/tuned/ppd.conf` | tuned silently downgraded GNOME "Balanced" to `balanced-battery` on battery, pinning EPP to `balance_power`. Slow CPU ramp-up reads as a sticky cursor. Costs some battery life. |
| `disable-while-typing=false` → **`true` since 2026-10-11** | gsettings | July: the 500 ms post-keystroke lockout on a 124×78 mm trackpad felt exactly like lag. October: the opposite complaint, a palm on the pad made the text cursor jump mid-typing, so it was turned back on. See *Touchpad on/off* below. |
| BT USB autosuspend off | `/etc/udev/rules.d/50-bluetooth-no-autosuspend.rules` | AX211 threw `Hardware error 0x0c` every ~5 min; each crash churned GNOME's input stack and stalled the touchpad ~700 ms. |
| Disable `usb3-port6` | `/etc/systemd/system/disable-usb3-port6.service` | Dead internal webcam retried enumeration forever (`error -71`). |
| `vm.swappiness=100`, `vm.page-cluster=0` | `/etc/sysctl.d/99-zram-tuning.conf` | Standard zram tuning — swapping to compressed RAM is cheap, and zram has no seek penalty. |
| Zero kbd backlight on shutdown | `/usr/lib/systemd/system-shutdown/kbd-backlight.shutdown` | The EC keeps driving the LED PWM after the host powers off, which looks like flickering. See below. |
| Touchpad resolution override | `/etc/udev/hwdb.d/61-evdev-elan-touchpad.hwdb` | Scroll speed — see below. |

## Touchpad on/off (2026-10-11)

**The problem:** brushing the trackpad while typing made the text cursor jump. Jose
asked for a key to switch the pad off and on.

| Change | Where |
| :--- | :--- |
| `disable-while-typing` back to `true`. This reverts the July tweak above; libinput pairs this pad with the internal `AT Translated Set 2 keyboard` | gsettings `org.gnome.desktop.peripherals.touchpad` |
| **Search + T** (`<Super>t`, which was free) toggles the pad. GNOME shows "Touchpad off" / "Touchpad on" | custom shortcut `custom0`, running `~/.local/bin/touchpad-toggle` |
| The toggle flips `send-events` between `enabled` and `disabled` | `~/.local/bin/touchpad-toggle`, hand-placed, not in this repo |

`tap-to-click` is still `true`. It is the next lever if the cursor keeps jumping.

If the post-typing lag from July comes back, revert only the first change and keep
the shortcut:

```bash
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
```

## Touchpad scroll tuning

**The problem:** two-finger scroll is far too fast out of the box, and there is no
setting for it anywhere.

This was verified, not assumed:

- **libinput 1.31 has no touchpad scroll-speed attribute.** Enumerating its quirk
  attributes turns up exactly one multiplier, `AttrTrackpointMultiplier`, and that
  is trackpoint-only.
- **GNOME 50 has no scroll-speed key.** Across every schema there is only
  `two-finger-scrolling-enabled`, `natural-scroll` and `edge-scrolling-enabled` —
  all on/off. The `speed` slider in Settings affects the **pointer only**.
- **`AttrResolutionHint` does not work here.** It only applies to devices that
  report no resolution; this pad correctly reports 31 u/mm (→ 123.6 × 78.2 mm,
  matching its true physical size).

**The lever:** libinput derives *both* pointer motion and scroll from physical
distance. Overriding the resolution the kernel advertises therefore scales scroll —
and unavoidably scales the pointer with it, which is compensated with the GNOME
`speed` slider.

```
/etc/udev/hwdb.d/61-evdev-elan-touchpad.hwdb

evdev:name:Elan Touchpad:dmi:*svnGoogle:pnGimble*
 EVDEV_ABS_00=0:3831:124
 EVDEV_ABS_01=0:2424:124
 EVDEV_ABS_35=0:3831:124
 EVDEV_ABS_36=0:2424:124
```

Format is `min:max:resolution`. **Higher resolution = slower scroll.** All four
axes must carry the same number. True resolution is 31; the current value is 124 (4×).

### Calibration log

| Value | Multiplier | Result |
| ---: | :--- | :--- |
| 31 | 1× (stock) | Far too fast everywhere — a small flick scrolled roughly a full page |
| 62 | 2× | Better, still too fast |
| 248 | 8× | Terminal good, **Nautilus too slow**, **cursor too slow** even at `speed 1.0` |
| **124** | **4× — settled** | Chrome, Nautilus and the cursor all good at `speed 0.8`. Confirmed in use, not just measured. |

4× is the answer. It was reached by overshooting to 8× first, which is what proved
the ceiling: at 8× the pointer ran out of compensation and Files became unusable,
while the terminal finally felt right. Chrome was the last doubt and tested fine
once everything else settled — so no per-app workaround was needed after all.

### To change it

```bash
sudoedit /etc/udev/hwdb.d/61-evdev-elan-touchpad.hwdb   # edit all four values
sudo systemd-hwdb update
sudo sh -c 'echo i2c-ELAN0000:00 > /sys/bus/i2c/drivers/elan_i2c/unbind'
sudo sh -c 'echo i2c-ELAN0000:00 > /sys/bus/i2c/drivers/elan_i2c/bind'
```

The unbind/bind makes GNOME re-read the device without logging out. Verify with
`sudo libinput list-devices | grep -A4 'Elan Touchpad'` — the reported `Size`
should shrink as the multiplier goes up (4× → `31x20mm`).

Then rebalance the pointer in **Settings → Mouse & Touchpad**, or:

```bash
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.8   # range -1.0 .. 1.0
```

To revert entirely: delete the hwdb file, `systemd-hwdb update`, rebind, and set
`speed` back to `0.0`.

### Before turning the knob further

Two ceilings are already close at 4×, and both get worse linearly:

- **The pointer runs out of compensation.** `speed` maxes at `1.0`, which was not
  enough at 8×.
- **Three- and four-finger gestures need proportionally more travel**, because
  their thresholds are in millimetres too.

More importantly, **apps do not agree on what a scroll delta means** — Chrome,
Nautilus and terminals each apply their own curve on top. That is why 8× fixed the
terminal while breaking Files, and it is the reason to be suspicious of any value
judged from a single app.

If one app ever drifts out of line again, fix it at the app layer rather than
moving the system-wide knob for everything else:

- **Chrome** has no scroll-speed setting on Linux — not in `chrome://flags`, not
  on the command line. The only real option is a browser extension that multiplies
  the scroll event. Note Chrome here is the **Flatpak** build (`/app/extra/chrome`),
  which does its own scroll handling and ignores the pad's reported geometry.
- **Firefox** does support it natively: `mousewheel.default.delta_multiplier_y`
  in `about:config`.

## Keyboard backlight

The LED is `chromeos::kbd_backlight` (max 100), driven by the ChromeOS EC through
`cros_kbd_led_backlight` / `GOOG0002:00` — not a standard ACPI LED. `ectool` is not
installed, so sysfs is the only interface.

**The symptom:** the backlight flickers once the host stops driving it. The EC keeps
the PWM running on its own, and a nonzero duty cycle with no host behind it is what
shows up as flicker.

**Why the host has to do this at all:** sleep state is **`s2idle`**, not `deep`
(`cat /sys/power/mem_sleep`). The EC never actually loses power, so nothing turns the
LED off implicitly — it has to be zeroed explicitly on every transition.

Three pieces cover the two transitions:

| Hook | Runs | What it does |
| :--- | :--- | :--- |
| `/etc/systemd/system/kbd-backlight-poweroff.service` | Poweroff / reboot / halt | Oneshot started during the shutdown transaction (`After=final.target`, `Before=systemd-poweroff.service` etc.) that writes 0; its execution is visible in the journal of the previous boot |
| `/usr/lib/systemd/system-shutdown/kbd-backlight.shutdown` | Poweroff / reboot | Backup: writes 0 again at the very end of shutdown, inside `systemd-shutdown` |
| `/usr/lib/systemd/system-sleep/kbd-backlight-suspend.sh` | Suspend / resume | Saves the value to `/var/lib/kbd-backlight-suspend.state`, writes 0 on `pre`, restores on `post` |

**History of the 2026-08 regression:** `kbd-backlight-poweroff.service` (from
2026-06-19) originally declared both `Before=shutdown.target` and
`After=final.target`. Since `final.target` is itself `After=shutdown.target`,
that is an ordering cycle, and systemd resolved it by **silently deleting the
service's job at every shutdown** ("Job kbd-backlight-poweroff.service/start
deleted to break ordering cycle" in the journal). The unit never ran even once.
The blinking stayed fixed anyway from 2026-07-25 on because the
`system-shutdown` hook covered it — until an update (systemd 259 landed
2026-08-01, kernels 7.1.5→7.1.8 through August) made that path stop being
sufficient and the poweroff blink returned. The unit was rewritten on
2026-08-23 without the cycle; the sysfs write itself was verified working live
the same day. To confirm it ran on the last shutdown:
`journalctl -b -1 -u kbd-backlight-poweroff.service`.

Kernels 7.1.x also added `leds_cros_ec`, which exposes two new EC LEDs
(`chromeos:multicolor:charging`, `chromeos:white:power`), both on the
`chromeos-auto` trigger. They are believed harmless, but they are the other
recent EC-LED-related change if blinking symptoms ever shift to those LEDs.

Neither is owned by a package — an OS upgrade will not recreate them. The suspend
hook predates the shutdown one and also invokes
`/usr/local/sbin/nvme-unsafe-shutdown-monitor.sh` on resume, which is unrelated
bookkeeping that happens to live in the same script.

The shutdown hook has to run *late*, after `systemd-backlight@leds:chromeos::kbd_backlight.service`
has already saved the brightness — otherwise zeroing it is what gets persisted and
the keyboard comes back dark on the next boot.

**On idle, GNOME does not turn the LED off.** `gsd-power` drops it to
`idle-brightness` (30) and leaves it there, so the keyboard stays dimly lit while the
screen is blanked. Verified 2026-07-26: steady at that level, no flicker — so this
needs no hook. Only the poweroff and suspend transitions did.

To watch what is actually driving the value, poll it — a fight between components
shows up as an oscillating number, while an EC-level flicker leaves it constant:

```bash
watch -n0.1 cat /sys/class/leds/chromeos::kbd_backlight/brightness
```

### 2026-08 regression root cause: EC-RW backlight driver left unregistered after an EC reset (2026-08-30)

The kernel was **not** the change agent: 7.1.3/7.1.4 were already running in July
when everything worked (journal), and the UEFI has been MrChromebox-2603.2 since at
least 2026-07-15. What changed is the state of the EC.

The EC runs a MrChromebox/chrultrabook EC-RW build (`gimble_v2.0.27860-0f0590ceec
gimble_16238.2+tbt5 2025-10-12 chrultrabook`; RO is the factory `v2.0.19511`),
loaded by coreboot's "EC Software Sync" (`google_chromeec_swsync()` in
`src/ec/google/chromeec/ec_sync.c`; UEFI setup options `ec_sw_sync` = "EC Software
Sync" and `ec_rw_jump` = "Use EC-RW Firmware" under "ChromeEC Embedded
Controller"). That RW is unsigned, so EFS2 never jumps to it on its own; coreboot
does a *late sysjump* into RW with the AP already in S0 on every boot that follows
an EC reset (EC hibernate after >1 h in G3 on battery, battery cut-off). In
`power/intel_x86.c` `power_chipset_init()` treats that as "already in S0" and fires
no `HOOK_CHIPSET_STARTUP`, but `common/keyboard_backlight.c` registers its driver
(`kblight_register(&kblight_pwm)`) **only** on `HOOK_CHIPSET_STARTUP` unless the
board defines `CONFIG_KBLIGHT_HOOK_INIT` — gimble does not (MrChromebox added it to
*mithrax* only, commit f1520542 of 2026-03-31, for exactly this reason). In that
state every `kblight_set()`/`kblight_enable()` is a no-op: sysfs and ACPI writes
are silently dropped, reads still succeed (they return the cached percent), and
the PWM stays wherever `board_pwm_init()` left it (enabled, 50 %). The suspend and
poweroff hooks therefore "successfully" write 0 while the EC keeps the PWM running,
and with the EC deep-sleeping in S0ix/S5 (the KBLIGHT channel has no
`PWM_CONFIG_DSLEEP`, so its clock stops and restarts) that shows as the
breathing/flicker. Warm reboots do not clear it; a full poweroff → boot does —
which is why the July fixes "worked", why brightness control comes and goes, and
why the EC honoured writes again in the boot after the 2026-08-30 poweroff. Same
board, same symptom, same cause: MrChromebox/firmware issue #952, where disabling
"Use EC-RW Firmware" (EC stays in RO) fixed it.

Verified live on 2026-08-30: EC uptime matched the 2026-08-28 boot exactly (EC
reset flags HIBERNATE|WAKE_PIN|SYSJUMP|POWER_ON, no EFS → the RW jump came from
the AP), and in the following boot a sysfs write of 0 makes the EC report
`percent=0 enabled=0` (`ec-kblight --query`). EC state can be read without
`ectool` through `/dev/cros_ec` (`CROS_EC_DEV_IOCXCMD`, 20-byte header); see
`/usr/local/sbin/ec-kblight` and the diagnostic `ec-console-logger.service`
(appends the EC console ring to `/var/log/ec-console.log`; the ring is only ~1 KB,
about 2 minutes of battery chatter).

Mitigations in place:

- `/usr/local/sbin/ec-kblight <percent|--query>` sends `EC_CMD_PWM_SET_DUTY`
  (type KB_LIGHT), which drives the PWM channel directly and works even when the
  driver layer is unregistered. All three backlight hooks call it in addition to
  the sysfs write (unit `ExecStart`, `system-shutdown` hook, `system-sleep` hook).
- Lid close powers off (below). GNOME's own brightness keys still cannot work in
  the degraded state; a full poweroff → boot restores them. Suspend can be
  reconsidered now that the cause is known (note `CREC` / `GOOG0004` ACPI wake is
  disabled by default in `/proc/acpi/wakeup`, which matters if s2idle is re-enabled
  and lid-open should wake).

Proper fix: `#define CONFIG_KBLIGHT_HOOK_INIT` in `board/gimble/board.h` of
MrChromebox/chrome-ec (as done for mithrax) plus a rebuilt EC-RW; or disable "Use
EC-RW Firmware" in the UEFI setup to stay on the factory RO (MrChromebox's help
text warns USB-C/TBT accessories or the keyboard may misbehave on RO).

### Lid close powers off (2026-08-30)

`/etc/systemd/logind.conf.d/50-lid-poweroff.conf` sets `HandleLidSwitch`,
`HandleLidSwitchExternalPower` and `HandleLidSwitchDocked` to `poweroff`; applied
live with `systemctl reload systemd-logind` (`CanReload=yes` on systemd 259).
Chosen by Jose after the breathing/drain episodes, before the root cause above
was found. Caveats:

- The EC boots the machine when the lid is opened while it is off
  (`powerbtn_x86_lid_change()` in `common/power_button_x86.c` pulses the power
  button whenever the chipset is off and the lid opens). EC firmware, cannot be
  disabled from Linux: "open lid" means a cold boot.
- GNOME still reaches suspend two other ways: the power button
  (`power-button-action = suspend`) and 15 min of idle
  (`sleep-inactive-{ac,battery}-type = suspend`, 900 s). `AllowSuspend=no` in
  `/etc/systemd/sleep.conf.d/` would close every path at once; not applied.

## Known issues — not worth fixing

- **The webcam does not work.** `usb3-port6` is a hardwired internal device that
  never enumerates (`error -71`); there is no `/dev/video*` at all. The port is now
  disabled to stop the retry storms. If a camera is ever needed, undo
  `disable-usb3-port6.service` first.
- **`cros-ec-spi` fails to probe every boot** (`Cannot identify the EC: -110`).
  Harmless MrChromebox noise — the working EC path is LPC (`cros_ec_lpcs`, `GOOG0004:00`).
- **Wi-Fi sits on 2.4 GHz.** The AX211 shares one antenna between Wi-Fi and
  Bluetooth, so a 2.4 GHz association degrades Bluetooth peripherals. Moving the AP
  to 5 GHz is the fix; it has not been done.
- **MAX98390 speaker firmware is missing** (`dsm_param_*.bin`). Audio works; the
  amps just run without their tuning blobs, which is the norm on Chromebooks
  outside ChromeOS.

## Dock: opted out of the dotfiles style (2026-10-24)

`install.sh` step 4c loads `gnome/dash-to-dock.ini` on every GNOME desktop, with the
apps grid at the end of the dock. Santi's dock is the one that style was copied from, but
his keeps the grid at the start, so `~/.zshrc.local` here exports `DOTFILES_GNOME_DOCK=0`.
Remove that line only if Santi wants Jose's dock.

## Debloat (2026-10-24)

Survey first (7.6 GiB, 3.6 available, Chrome 3.7 GB, about 1.4 GB in idle background
services), then Jose approved removing what the machine does not need. Done over SSH.

| Change | Detail |
| :--- | :--- |
| Removed | `abrt*` + `gnome-abrt`, `ibus-typing-booster`, VM guest tools (`open-vm-tools*`, `qemu-guest-agent`, `spice-vdagent`, `virtualbox-guest-additions`), `mediawriter`, `gnome-tour`, `wezterm` + its COPR, the **RPM** `google-chrome-stable` (the Flatpak `com.google.Chrome` is the one in use, profile in `~/.var`), `rygel`, `gnome-user-share`, `livesys-scripts`, `rsyslog`, `sysstat`, `plocate`, `stratis*`, `ModemManager` (+ `NetworkManager-wwan`/`-bluetooth`). Run with `clean_requirements_on_remove=False`: the auto-cleanup wanted gdb, emoji fonts and more |
| Disabled, not removed | `iscsi*` and `multipathd` (removing them drags `libvirt-daemon-kvm` + `qemu`), `mdmonitor` + `raid-check.timer` (**`mdadm` removal drags gdm, gnome-shell and nautilus**), `lvm2-monitor`, `NetworkManager-wait-online`, `virtqemud` |
| User session | `gnome-software.service` masked with the D-Bus override from `geeklab-infra/docs/low-ram-laptop-fedora.md` (the app still opens); `evolution-alarm-notify` masked + autostart hidden (it ships inside `evolution-data-server`, which the shell calendar needs); stale `remmina-applet` autostart deleted (Remmina itself was already uninstalled) |
| Updates instead of gnome-software | `dnf5-automatic.timer`, **security updates only**, applied, never reboots (`/etc/dnf/automatic.conf`); `flatpak-update.timer`, weekly `flatpak update --system` + unused-runtime cleanup (`/etc/systemd/system/flatpak-update.*`) |
| Disk | unused Flatpak runtimes 20 → 15 (9.0 → 7.7 GB), journal capped at 100 MB (was 834 MB), dnf and gnome-software caches |
| Default browser | `mimeapps.list` handlers moved from `google-chrome.desktop` to `com.google.Chrome.desktop` |

Kept on purpose, still open questions for Jose: Cloudflare WARP (installed, unregistered),
Docker (disabled) and libvirt, GPaste, Maps/Weather/Contacts/Connections/Simple Scan,
`localsearch`. RAM gains show after the next reboot: processes of removed packages and
the daemons gnome-software woke keep running until then.

**After the reboot, gnome-software came back anyway**, D-Bus-activated 30 s after login
(`app.slice/dbus-:1.2-org.gnome.Software@0.service`): it is a GNOME Shell **search
provider**, so searching in Activities wakes it, and it pulls Flathub appstream and wakes
`dnf5daemon` + `flatpak-system-helper`. Fixed with
`gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Software.desktop']"`
(installed apps still show in search; only store suggestions are gone).

### Second pass (2026-10-24, same evening)

- **Cloudflare WARP removed** (`cloudflare-warp` + its repo): installed but never
  registered, ~288 MB for `warp-svc` + `warp-taskbar`.
- **Orphaned packages:** 53 removed by hand from the `dnf autoremove` list: anaconda and its
  python libs, the `httpd` stack (pulled in by `gnome-user-share`), `libreport`/`satyr`
  (abrt), `gupnp`/`libmediaart` (rygel), `pcp`, `libestr`/`libfastjson` (rsyslog),
  `libmbim`/`libqmi` utils, `wezterm-mux-server`, `tmux`. **Kept on purpose** although
  autoremove offers them: fonts (`liberation-fonts-all`, emoji, Symbola, Montserrat), `gdb`,
  `wl-clipboard`, the python3 libs, `clevis`/`luks`, `libblockdev*`, multipath.
- **Orphan files:** `agy.*.old` (224 MB), abrt spool (70 MB), coredumps (43 MB), stale
  headless-Chrome temp dirs from Playwright, empty Remmina/WezTerm dirs, package caches.
  373 MB freed on `/` in this pass.
- **Broken config symlinks fixed:** `~/.config/btop/btop.conf` and
  `~/.config/Code/User/{settings,keybindings,tasks}.json` pointed at
  `/home/geekendzone/repos/fedora-workstation-replica/...`, a GeekForge path that does not
  exist here. Replaced with real copies from `jacedeno/fedora-workstation-replica`
  (`capture/dotfiles/`). That repo's replicate step should copy, not symlink to its own
  checkout.
- **`gnome-software --quit` is not a stop command**: if Software is not running it
  D-Bus-activates it first. Stop it with
  `systemctl --user stop 'dbus-:1.2-org.gnome.Software@*.service'`.
- Left for Jose: `~/.config/google-chrome` is the removed RPM Chrome's profile and holds
  `History` + `Login Data`; `~/Downloads` has a service-account JSON
  (`excemca-esbd-poller-*.json`) and two copies of a Windows installer (`gamejoltclientsetup*.exe`, 171 MB).

Measured after the reboot, Chrome open: **4.4–4.8 GB available** (3.8 before).

### Third pass (2026-10-24): parity with C2-B5

- Removed Docker (`docker-ce*`, `containerd.io`, buildx/compose, the `docker` group and
  repo; no images or data existed), the libvirt/qemu leftovers (`libvirt-libs`,
  `libvirt-client`, `python3-libvirt`, `virt-install`; no VMs were defined) and GPaste
  (a clipboard history, not a screenshot tool; its extension was never enabled).
- The removed RPM Chrome's profile held 0 saved passwords, 3 history rows and no
  bookmarks, so there was nothing to import into the Flatpak; deleted.
- `~/Downloads/excemca-esbd-poller-*.json` was a byte-identical copy of the live
  gov-contracts key; added to `homelab-secrets` (it was missing there) and deleted here.
- Dotfiles pulled to the same commit as C2-B5 and `install.sh` re-run (with
  `DOTFILES_GNOME_DOCK=0` on the command line: over SSH `~/.zshrc.local` is not read).
  `~/.config/herdr/config.toml` replaced by C2-B5's (backup `config.toml.bak-2026-10-24`;
  the old one had `status_indicators = "symbols"`); the unused `~/.oh-my-zsh` leftover
  removed. Remaining differences are machine-local on purpose: `~/.zshrc.local`, and
  Oh My Posh 31.9.1 here (`~/.local/bin`) vs 30.5.0 from the Fedora package on C2-B5.
