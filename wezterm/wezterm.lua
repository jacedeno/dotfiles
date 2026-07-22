-- ==============================================================================
-- ~/.config/wezterm/wezterm.lua — jacedeno dotfiles
-- One config for every machine: Linux (daily driver), macOS (laptop) and
-- Windows 11 (work, portable zip — no install needed). Shell setup lives in
-- zsh/.zshrc and is untouched by the terminal: wezterm just launches the
-- default shell.
-- ==============================================================================

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_macos = wezterm.target_triple:find("darwin") ~= nil

-- --- Font (same as the old terminator setup, plus ligatures) -------------------
config.font = wezterm.font("FiraCode Nerd Font Mono")
-- 12pt on a Retina panel renders noticeably smaller than on the Linux displays.
config.font_size = is_macos and 13.0 or 12.0

-- --- Colors: Tokyo Night, matching the fzf palette in .zshrc -------------------
-- Background overridden to pure black like the old terminator profile; the
-- rest of the palette (ANSI colors, cursor, selection) stays Tokyo Night.
config.color_scheme = "Tokyo Night"
config.colors = {
  background = "#000000",
}

-- --- Window / tabs --------------------------------------------------------------
-- GNOME Wayland draws no server-side decorations, so integrate the title and
-- min/max/close buttons into wezterm's tab bar and enable drag-to-resize edges.
-- The tab bar must stay visible: it IS the title bar (drag it to move the window).
-- macOS does draw its own decorations, so keep the native title bar and traffic
-- lights there instead of wezterm's drawn buttons.
config.window_decorations = is_macos and "TITLE|RESIZE" or "INTEGRATED_BUTTONS|RESIZE"
config.hide_tab_bar_if_only_one_tab = false
config.scrollback_lines = 10000
config.check_for_updates = false -- updates: wezterm-nightly COPR (dnf) / brew cask

-- --- GPU rendering --------------------------------------------------------------
-- Pin the modern WebGpu backend (Vulkan/Metal/DX12) instead of relying on the
-- version default, and ask for the discrete/high-performance adapter. On the
-- Linux daily driver this selects the AMD Radeon Pro WX 4100 over the Intel UHD
-- 630 iGPU; on the MacBook it prefers the discrete GPU when present. Verify the
-- chosen adapter at runtime from the debug overlay (Ctrl+Shift+L):
--   wezterm.gui.enumerate_gpus()
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

if is_macos then
  -- Use a real macOS fullscreen Space (green button / Ctrl+Cmd+F) rather than
  -- wezterm's borderless fill of the current Space.
  config.native_macos_fullscreen_mode = true
end

-- --- Keys: terminator muscle memory ----------------------------------------------
-- Ctrl+Shift+E = side by side, Ctrl+Shift+O = stacked, Ctrl+Shift+W = close PANE
-- (wezterm's default closes the whole tab), Ctrl+Shift+X = zoom pane, Alt+arrows =
-- move between panes. Everything else uses wezterm defaults (Ctrl+Shift+T new tab,
-- Ctrl+Shift+C/V copy/paste, Ctrl+Shift+F search, Ctrl +/-/0 font size).
-- Pane resize differs from terminator: Ctrl+Shift+ALT+arrows (Ctrl+Shift+arrows
-- also navigates panes, wezterm default).
-- These bindings apply on macOS too, so the muscle memory carries over; the
-- native Cmd+C/V/T/N/W defaults keep working there alongside them.
--
-- Ctrl+Shift+K = copy mode. Taking Ctrl+Shift+X for zoom (terminator muscle
-- memory) displaced wezterm's default ActivateCopyMode binding, which left no
-- way to select and copy text from the keyboard. That matters inside full-screen
-- TUIs (claude, vim, k9s): they capture the mouse, so dragging selects nothing
-- unless you hold Shift to bypass mouse reporting. Copy mode and Ctrl+Shift+Space
-- (QuickSelect, a wezterm default) both work with no mouse at all.
config.keys = {
  { key = "E", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "O", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "W", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "X", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },
  { key = "K", mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
  { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
  { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
  -- F2 = rename the current tab (empty input keeps the automatic title)
  {
    key = "F2",
    mods = "NONE",
    action = act.PromptInputLine({
      description = "Rename tab",
      action = wezterm.action_callback(function(window, _pane, line)
        if line and #line > 0 then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
}

-- On macOS, add the native split shortcuts alongside the terminator ones, so the
-- muscle memory from other Mac terminals (iTerm2, Ghostty) also lands.
if is_macos then
  table.insert(config.keys, { key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) })
  table.insert(config.keys, { key = "D", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) })
end

-- --- Mouse: right-click pastes (wezterm has no context menu by design) ----------
-- Selecting text already copies it; middle-click pastes the primary selection.
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = "Right" } },
    mods = "NONE",
    action = act.PasteFrom("Clipboard"),
  },
}

-- --- SSH domain: geekforge -------------------------------------------------------
-- Open a remote tab with:  wezterm connect geekforge   (or the Launcher menu)
-- remote_address can be a hostname, IP, or a Host entry from ~/.ssh/config.
-- multiplexing = "None" works against plain sshd; switch to "WezTerm" after
-- installing wezterm-mux-server on geekforge to get persistent remote panes.
config.ssh_domains = {
  {
    name = "geekforge",
    remote_address = "geekforge", -- resolved by each machine's ~/.ssh/config Host entry
    username = "root",
    multiplexing = "None",
  },
}

-- --- Windows --------------------------------------------------------------------
-- WSL is the primary shell here too: it runs the same zsh + dotfiles as the Linux
-- machines (clone the repo inside WSL and run ./install.sh there). WezTerm launches
-- the default WSL distro in the Linux home. For native PowerShell instead, swap for
-- { "pwsh.exe", "-NoLogo" } (PS 7) or { "powershell.exe", "-NoLogo" } (Windows PS 5).
if is_windows then
  config.default_prog = { "wsl.exe", "--cd", "~" }
end

return config
