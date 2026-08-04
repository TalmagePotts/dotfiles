# Talmage's Brewfile — the lean macOS baseline.
# Installed by default: ./install.sh
#
# Three tiers, smallest first:
#
#   Brewfile           this file. Terminal tools + the handful of GUI apps that
#                      are load-bearing or that I want on literally every Mac.
#                      No App Store login required, nothing over ~500MB.
#   Brewfile.apps      coding apps and niche CLI utilities. Opt in with
#                      `./install.sh --with-apps`. This is where Xcode lives.
#   Brewfile.optional  multi-GB and per-project installs. Never automatic.
#
# This file is the Mac half of the core package list in install.sh; the apt
# block there is the Linux half. Anything the stowed dotfiles depend on belongs
# in BOTH, and belongs in this tier rather than the other two.
#
# No taps: everything here resolves from homebrew/core and homebrew/cask.
#
# Not here on purpose: uv, rustup/cargo, claude, ccstatusline, worktrunk. Those
# use their own installers and install.sh handles them cross-platform.

# ── CLI: depended on by the stowed config ────────────────────────────────────
# Removing any of these breaks something concrete — the reference is in comments.
brew "atuin"           # Shell history with sync (.zshrc)
brew "bat"             # Previewer for the fs/ff/ffd/ffq fzf aliases (.zshrc)
brew "direnv"          # Per-directory env vars (.zshrc)
brew "fd"              # ff/ffd/ffq aliases (.zshrc)
brew "fzf"             # fs/fsg/ff/ffd/ffq aliases, gwcp project picker (.zshrc)
brew "gh"              # gwc/gwcp draft-PR creation (.zshrc)
brew "jq"              # wtclean worktree filtering (.zshrc)
brew "lazygit"         # lg alias (.zshrc), config in terminal/.config/lazygit
brew "neovim"          # the whole nvim stow package
brew "node"            # Node.js; npm installs ccstatusline
brew "powerlevel10k"   # Zsh theme (.zshrc, .p10k.zsh)
brew "ripgrep"         # fs/fsg aliases (.zshrc)
brew "stow"            # install.sh links every dotfile with this
brew "tmux"            # terminal/.config/tmux
brew "zoxide"          # .zshrc

# ── CLI: small, wanted everywhere ────────────────────────────────────────────
brew "ccusage"         # Claude Code cost tracker
brew "git-filter-repo" # Rewrite git history
brew "git-lfs"         # Git large file storage

# ── GUI: load-bearing or universal ───────────────────────────────────────────
cask "ghostty"         # Terminal — config in terminal/.config/ghostty
cask "hammerspoon"     # macOS automation — config in mac/.hammerspoon
cask "moonlight"       # Game streaming client
cask "obsidian"        # Notes
cask "tailscale-app"   # Tailnet — install.sh's closing steps tell you to sign in

# Fonts
cask "font-meslo-lg-nerd-font"  # Required for Powerlevel10k prompt
