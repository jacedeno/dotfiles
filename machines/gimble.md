# gimble — Chromebook running Fedora

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
| Battery | Li-ion, 5095 mAh design / 4534 mAh full (~89 % health), 5 cycles |

`dmidecode` reports the RAM as 2× 1 GiB. That is a firmware quirk — trust
`/proc/meminfo` (7.6 GiB), not DMI.

## Software

| | |
| :--- | :--- |
| OS | Fedora 44 |
| Kernel | 7.1.4-204.fc44.x86_64 |
| Desktop | GNOME Shell 50.3 on **Wayland** |
| Filesystem | btrfs on `/dev/nvme0n1p3`, subvolumes `root` + `home`; ext4 `/boot`, vfat ESP |
| Swap | zram 7.6 GB (`lzo-rle`) — no disk swap |
| Power | `tuned` + `tuned-ppd` (**not** `power-profiles-daemon`), plus `thermald` |

## Dotfiles state

Everything from this repo is installed and symlinked normally:

| Path | Points to |
| :--- | :--- |
| `~/.zshrc` | `zsh/.zshrc` |
| `~/.gitconfig` | `git/.gitconfig` |
| `~/.config/wezterm/wezterm.lua` | `wezterm/wezterm.lua` |
| `~/.config/terminator/config` | `terminator/config` |
| `~/.local/bin/clip2forge` | `bin/clip2forge` |
| `~/.local/bin/mount-excemca` | `bin/mount-excemca` |

`~/.config/ohmyposh/atomic.omp.json` is a **copy**, not a symlink — that is by
design, `install.sh` vendors the theme so the prompt works offline.

Versions here: zsh 5.9, Oh My Posh 29.17.0, WezTerm `20260716` (nightly COPR).

### `~/.zshrc.local`

Deliberately almost empty. Only one alias:

```zsh
alias claude-yolo="claude --dangerously-skip-permissions"
```

### WezTerm note specific to this machine

`wezterm/wezterm.lua` sets:

```lua
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
```

The comment there explains `HighPerformance` picks the *AMD Radeon Pro WX 4100 over
the Intel UHD* — **that reasoning is about the other Linux machine, not this one.**
This Chromebook has no discrete GPU. `wezterm.gui.enumerate_gpus()` here returns:

```
Vulkan | IntegratedGpu | Intel(R) Graphics (ADL GT2)
Vulkan | Cpu           | llvmpipe
Gl     | IntegratedGpu | Mesa Intel(R) Graphics (ADL GT2)
```

So `HighPerformance` is a no-op — there is nothing to prefer. It is harmless and
left alone for config portability, but do not expect it to do anything here, and
be aware `llvmpipe` (software rendering) is in that list: if WezTerm ever feels
catastrophically slow, confirm it did not land on the CPU backend.

## System tweaks applied

Applied 2026-07-25 while chasing touchpad lag and general sluggishness. None of
these are managed by `install.sh` — they are hand-placed system files.

| Change | Where | Why |
| :--- | :--- | :--- |
| `battery_detection=false` | `/etc/tuned/ppd.conf` | tuned silently downgraded GNOME "Balanced" to `balanced-battery` on battery, pinning EPP to `balance_power`. Slow CPU ramp-up reads as a sticky cursor. Costs some battery life. |
| `disable-while-typing=false` | gsettings | The 500 ms post-keystroke lockout on a 124×78 mm trackpad feels exactly like lag. |
| BT USB autosuspend off | `/etc/udev/rules.d/50-bluetooth-no-autosuspend.rules` | AX211 threw `Hardware error 0x0c` every ~5 min; each crash churned GNOME's input stack and stalled the touchpad ~700 ms. |
| Disable `usb3-port6` | `/etc/systemd/system/disable-usb3-port6.service` | Dead internal webcam retried enumeration forever (`error -71`). |
| `vm.swappiness=100`, `vm.page-cluster=0` | `/etc/sysctl.d/99-zram-tuning.conf` | Standard zram tuning — swapping to compressed RAM is cheap, and zram has no seek penalty. |
| Zero kbd backlight on shutdown | `/usr/lib/systemd/system-shutdown/kbd-backlight.shutdown` | The EC keeps driving the LED PWM after the host powers off, which looks like flickering. |
| Touchpad resolution override | `/etc/udev/hwdb.d/61-evdev-elan-touchpad.hwdb` | Scroll speed — see below. |

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
