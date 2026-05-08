# 🚀 Tmux Complete Command Reference

**Prefix Key: `Ctrl+A`** (All commands below start with this unless noted)

---

## Quick Reference Table

| Category | Key | Action |
|----------|-----|--------|
| **🪟 WINDOWS** | | |
| | `Ctrl+C` | Create new window (in current path) |
| | `H` | Previous window |
| | `L` | Next window |
| | `Ctrl+A` | Toggle to last window |
| | `w` or `Ctrl+W` | List all windows |
| | `r` | Rename current window |
| | `"` | Choose window interactively |
| **📱 SPLIT PANES** | | |
| | `\|` | Split horizontal (side by side) |
| | `s` | Split vertical (top/bottom) |
| | `v` | Split horizontal (alternative) |
| **🧭 NAVIGATE PANES** | | |
| | `h` | Move to left pane |
| | `j` | Move to down pane |
| | `k` | Move to up pane |
| | `l` | Move to right pane |
| | `z` | Toggle pane zoom (fullscreen) |
| **📏 RESIZE PANES** | | |
| | `,` | Shrink left 20 cols (repeatable) |
| | `.` | Grow right 20 cols (repeatable) |
| | `-` | Shrink down 7 rows (repeatable) |
| | `=` | Grow up 7 rows (repeatable) |
| **🎯 PANE ACTIONS** | | |
| | `c` | Kill current pane |
| | `x` | Swap pane down |
| | `*` | Synchronize all panes (type in all at once) |
| | `P` | Toggle pane border status display |
| **🎪 SESSIONS** | | |
| | `o` | 🌟 SessionX - Fuzzy finder + zoxide integration |
| | `S` | Choose session from list |
| | `Ctrl+D` | Detach from current session |
| **🎨 PLUGINS** | | |
| | `p` | 🌟 Floax - Toggle floating terminal (80% size) |
| | `Space` | 🌟 Thumbs - Hint mode (select text/URLs/paths) |
| | `u` | 🌟 FZF URL - Open URLs from history |
| | `I` | Install/update TPM plugins |
| | `U` | Update all plugins |
| **📋 COPY MODE** | | |
| | `[` | Enter copy mode (vi-style) |
| | `v` | Begin selection (in copy mode) |
| | `y` | Yank/copy selection |
| | `]` | Paste copied text |
| **⚙️ SYSTEM** | | |
| | `R` | Reload tmux configuration |
| | `K` | Clear terminal screen |
| | `:` | Open command prompt |
| | `Ctrl+L` | Refresh client display |
| | `Ctrl+X` | Lock server |

---

## 🎁 Always-On Features

- ✅ **Mouse Support** - Click panes, drag borders, scroll with trackpad
- ✅ **Auto-Save Sessions** - Every 15 min + auto-restore on startup
- ✅ **1M Line History** - Scroll back up to 1,000,000 lines
- ✅ **Smart Clipboard** - Copy/paste syncs with macOS clipboard
- ✅ **Vi Keybindings** - In copy mode and command editing
- ✅ **Catppuccin Theme** - Beautiful purple/pink status bar
- ✅ **No Exit on Close** - Switches to another session instead of exiting
- ✅ **Auto Window Renumber** - Windows renumber automatically when one closes

---

## 🌟 Power User Tips

### SessionX (`Ctrl+A o`)
The most powerful command in this config. Opens a fuzzy finder that:
- Lists all tmux sessions
- Integrates with zoxide (frecency-based directory jumping)
- Shows recently/frequently used project directories
- Creates new sessions on the fly
- Press `Ctrl+Y` to open in a new window

### Floax (`Ctrl+A p`)
Creates a temporary floating terminal (80% of screen) perfect for:
- Quick commands without disrupting your layout
- Temporary calculations or notes
- Running one-off scripts
- Disappears when you exit

### Thumbs Hint Mode (`Ctrl+A Space`)
Like browser link hints (Vimium/Surfingkeys) but for your terminal:
- Shows letter hints over text patterns
- Type the letters to copy paths, URLs, git hashes, etc.
- No mouse needed for precision selection

### Resize Panes (Repeatable Keys)
When resizing with `,` `.` `-` `=`:
- Hold `Ctrl+A`, then spam the resize key
- You don't need to press the prefix each time
- Makes quick adjustments super fast

### Synchronize Panes (`Ctrl+A *`)
Execute the same command on multiple panes simultaneously:
- Perfect for deploying to multiple servers
- Running parallel operations
- Batch configuration changes
- Toggle on/off with the same command

---

## 📦 Installed Plugins

1. **TPM** - Tmux Plugin Manager
2. **tmux-sensible** - Sensible default settings
3. **tmux-yank** - Enhanced copy/paste functionality
4. **tmux-resurrect** - Save/restore sessions manually
5. **tmux-continuum** - Auto-save/restore sessions
6. **tmux-thumbs** - Hint-based text selection
7. **tmux-fzf** - FZF integration for tmux
8. **tmux-fzf-url** - URL opener with FZF
9. **catppuccin-tmux** - Beautiful theme (omerxx fork)
10. **tmux-sessionx** - Advanced session manager with zoxide
11. **tmux-floax** - Floating terminal windows

---

## 🛠️ Troubleshooting

### Plugins Not Loading
```bash
# Delete empty plugin directories and reinstall
rm -rf ~/.config/tmux/plugins/*
~/.tmux/plugins/tpm/bin/install_plugins

# Restart tmux
tmux kill-server
tmux
```

### Theme Not Showing
```bash
# Reload config
Ctrl+A R

# Or restart tmux completely
tmux kill-server && tmux
```

### Update All Plugins
```bash
Ctrl+A U
# Or manually:
~/.tmux/plugins/tpm/bin/update_plugins all
```

---

## 📝 Configuration Files

- **Main Config**: `~/.config/tmux/tmux.conf`
- **Keybindings**: `~/.config/tmux/tmux.reset.conf`
- **Plugins**: `~/.config/tmux/plugins/`
- **Scripts**: `~/.config/tmux/scripts/`

---

## 🔗 Plugin Documentation

- [TPM](https://github.com/tmux-plugins/tpm)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)
- [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs)
- [SessionX](https://github.com/omerxx/tmux-sessionx)
- [Floax](https://github.com/omerxx/tmux-floax)
- [Catppuccin Theme](https://github.com/catppuccin/tmux)

---

**Last Updated**: 2026-01-29
**Tmux Version**: 3.6a
**Config Location**: `/Users/talmage/code/dotfiles/terminal/.config/tmux/`
