# A Guide to Your Neovim Configuration

Welcome to your new, powerful Neovim setup! This configuration is built on [LazyVim](https://www.lazyvim.org/), a starter template that provides a solid foundation with many features out of the box. This guide will walk you through the core concepts and keybindings to get you productive quickly.

---

## 1. The Leader Key: Your Command Center

Your "Leader" key is **`space`**.

Think of it as your primary shortcut key, like a "command" button. Whenever you see `<leader>` in a shortcut, it means "press the `space` bar".

### Your Built-in Cheat Sheet: `which-key`

This configuration is smart. When you press `<leader>` and wait a moment, a menu will pop up showing you all the possible commands you can use. This is your most powerful tool for discovering new features!

---

## 2. Navigating Files, Folders, and Buffers

This is a core part of any editor workflow. Here’s how you can do it in your new setup.

### A. The File Explorer (`neo-tree`)

You have a file explorer similar to VS Code's.

-   **Toggle Explorer:** Press **`cmd` + `s`** to open and close the file tree on the left.
-   **Focus Explorer:** To move your cursor from your code to the file explorer window, press **`CTRL-w`** then **`h`**. To move back, press **`CTRL-w`** then **`l`**.

Once the file tree is open, you can use these keys:

| Key | Action |
|---|---|
| **`j`** / **`k`** | Move up and down. |
| **`Enter`** | Open the selected file or directory. |
| **`a`** | Add a new file or directory. |
| **`d`** | Delete the selected file or directory. |
| **`r`** | Rename the selected file or directory. |
| **`?`** | Show a help window with all available commands. |

### B. Finding Files Instantly (`Telescope`)

Instead of manually browsing the file tree, you can use a "fuzzy finder" to jump to any file instantly.

-   **Find Files:** Press **`shift` + `cmd` + `o`** (or the LazyVim default **`<leader>ff`**).
-   **How it works:** Start typing parts of the file path you're looking for (e.g., `conf key` to find `lua/config/keymaps.lua`). Telescope will instantly show you the best matches.

### C. Searching for Text (`Telescope`)

You can also search for specific text *within* all the files in your project.

-   **Find Text (Live Grep):** Press **`<leader>fg`**.
-   **How it works:** Type any text (e.g., a function name or a variable), and Telescope will show you every line in your project where that text appears.

### D. Managing Open Files (Buffers)

In Vim, open files are called "buffers". You don't need to manually save and close files all the time; you can keep many buffers open and switch between them.

-   **Cycle Through Buffers:**
    -   Press **`<leader>]`** to go to the *next* open file.
    -   Press **`<leader>[`** to go to the *previous* open file.
-   **Search Open Buffers:** Press **`<leader>fb`** to open Telescope and fuzzy-find from your list of currently open files.
-   **Close Buffers:**
    -   **`<leader>bd`**: Close the current buffer.
    -   **`<leader>bD`**: Close the current buffer *and* its window (split).
    -   **`<leader>bo`**: Close all *other* open buffers.
    -   **`<leader>qq`**: Quit Neovim entirely.

---

## 3. Your Custom Workflow

These are special commands tailored for you.

| Keybinding | Action | Description |
|---|---|---|
| **`cmd` + `r`** | Run Current File | A powerful, context-aware command that runs Swift, Dart, Elixir, and Python files. |
| **`cmd` + `/`** | Toggle Comment | Comments or un-comments the current line or visual selection. |

### The Integrated Terminal

| Keybinding | Action | Description |
|---|---|---|
| **`shift` + `cmd` + `y`** | Open Terminal | Opens a terminal at the bottom of the screen. |
| **`ESC`** | Exit Terminal Mode | While inside the terminal, press `ESC` to return to Normal mode. |
| **`:q`** | Close Terminal | After exiting to Normal mode, type `:q` to close the terminal window. |

---

## 4. Code Intelligence (LSP)

Your setup includes a Language Server Protocol (LSP) client, giving you modern, IDE-like features for your code.

| Keybinding | Action |
|---|---|
| **`g` `d`** | Go to Definition of the symbol under your cursor. |
| **`g` `r`** | Find all References to the symbol under your cursor. |
| **`K`** (Shift + k) | Show Documentation for the symbol under your cursor. |
| **`<leader>` + `r`** | Rename the symbol under your cursor across your entire project. |
| **`<leader>` + `c` `a`** | Show available Code Actions (like "add missing import" or "implement interface"). |

---

## 5. First Steps

1.  **Open Neovim:** `nvim`
2.  **Sync Plugins:** If you haven't already, run the command **`:Lazy sync`** and press Enter. This will download and install all the plugins.
3.  **Explore!** Press **`<leader>`** (`space`) and look at the pop-up menu. It's the best way to see what's possible.

Happy coding!
