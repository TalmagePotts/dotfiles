#!/bin/bash
# Talmage's Mac Bootstrap Script
# Usage on fresh Mac:
#   git clone https://github.com/YOURUSERNAME/dotfiles.git ~/code/dotfiles
#   cd ~/code/dotfiles && chmod +x install.sh && ./install.sh

set -e

DOTFILES="$HOME/code/dotfiles"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()   { echo -e "\n${GREEN}==> $1${NC}"; }
manual() { echo -e "  ${YELLOW}[MANUAL]${NC} $1"; }

# ── 1. Xcode Command Line Tools ─────────────────────────────────────────────
step "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "Finish the Xcode CLT install, then re-run this script."
  exit 1
fi

# ── 2. Homebrew ──────────────────────────────────────────────────────────────
step "Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── 3. Oh My Zsh ─────────────────────────────────────────────────────────────
step "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "  already installed"
fi

# ── 4. Apps via Brewfile ─────────────────────────────────────────────────────
step "Installing apps (this takes a while)..."
brew bundle install --file="$DOTFILES/Brewfile"

# ── 4. Symlink dotfiles via stow ─────────────────────────────────────────────
step "Linking dotfiles..."
mkdir -p ~/.config
mkdir -p ~/.claude
mkdir -p ~/.ssh
chmod 700 ~/.ssh
stow -t ~ home
# stow skips individual files inside dirs with non-stow content
ln -sf "$DOTFILES/home/.claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/home/.claude/CLAUDE.md"     ~/.claude/CLAUDE.md

# ── 5. Tmux plugins via TPM ──────────────────────────────────────────────────
step "Installing tmux plugins..."
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
# Install all plugins non-interactively
"$TPM_DIR/bin/install_plugins"

# ── 7. Git identity ──────────────────────────────────────────────────────────
step "Configuring git..."
git config --global user.name  "Talmage Potts"
git config --global user.email "klavierplayer23@gmail.com"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo " Done! A few manual steps left:"
echo "=================================================="
manual "Add secrets to Keychain (if iCloud Keychain is on, these sync automatically):"
manual "  security add-generic-password -s dotfiles -a DATABASE_URL -w '<value>'"
manual "  security add-generic-password -s dotfiles -a SUPABASE_ACCESS_TOKEN -w '<value>'"
manual "SSH key: ssh-keygen -t ed25519 -C 'klavierplayer23@gmail.com'"
manual "Add SSH key to GitHub: cat ~/.ssh/id_ed25519.pub | pbcopy → github.com/settings/keys"
manual "Add SSH key to each server: ssh-copy-id teapot@jarvis (iris, atlas, etc.)"
manual "Sign into App Store, then re-run: brew bundle install (for MAS apps)"
manual "Tailscale: open app → sign in with your account"
manual "Run: gh auth login"
manual "Run: atuin login"
manual "Raycast: open it → sign in → enable cloud sync"
manual "Sign into: Arc, Cursor, GitHub Desktop, Obsidian, etc."
