-- ==============================================================================
-- ~/.config/wezterm/wezterm.lua — jacedeno dotfiles
-- One config for every machine: Linux (daily driver) and Windows 11 (work,
-- portable zip — no install needed). Shell setup lives in zsh/.zshrc and is
-- untouched by the terminal: wezterm just launches the default shell.
-- ==============================================================================

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- --- Font (same as the old terminator setup, plus ligatures) -------------------
config.font = wezterm.font("FiraCode Nerd Font Mono")
config.font_size = 12.0

-- --- Colors: Tokyo Night, matching the fzf palette in .zshrc -------------------
config.color_scheme = "Tokyo Night"

-- --- Window / tabs --------------------------------------------------------------
-- GNOME Wayland draws no server-side decorations, so integrate the title and
-- min/max/close buttons into wezterm's tab bar and enable drag-to-resize edges.
-- The tab bar must stay visible: it IS the title bar (drag it to move the window).
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.hide_tab_bar_if_only_one_tab = false
config.scrollback_lines = 10000
config.check_for_updates = false -- updates come from the COPR (dnf) on Linux

-- --- Keys: terminator-style splits ----------------------------------------------
-- Ctrl+Shift+E = side by side, Ctrl+Shift+O = stacked (terminator muscle memory).
-- Everything else uses wezterm defaults (Ctrl+Shift+T new tab, Ctrl+Shift+C/V copy/paste).
config.keys = {
  { key = "E", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "O", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
}

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

-- --- Windows (work laptop) --------------------------------------------------------
if is_windows then
  -- Swap for { "pwsh.exe", "-NoLogo" } if PowerShell 7 is available.
  config.default_prog = { "powershell.exe", "-NoLogo" }
end

return config
