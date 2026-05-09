#!/bin/bash
# Talmage's Mac Bootstrap Script
# Usage on fresh Mac:
#   git clone https://github.com/YOURUSERNAME/dotfiles.git ~/code/dotfiles
#   cd ~/code/dotfiles && chmod +x install.sh && ./install.sh

set -uo pipefail
# Allow specific commands to fail without aborting (used with || true)

DOTFILES="$HOME/code/dotfiles"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step()    { echo -e "\n${GREEN}==> $1${NC}"; }
ok()      { echo -e "  ${GREEN}✓${NC} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
manual()  { echo -e "  ${YELLOW}[MANUAL]${NC} $1"; }
fail()    { echo -e "  ${RED}✗${NC} $1"; }

# ── 1. Xcode Command Line Tools ─────────────────────────────────────────────
step "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  echo "  Installing Xcode CLT..."
  xcode-select --install
  warn "Finish the Xcode CLT install, then re-run this script."
  exit 1
else
  ok "Xcode CLT already installed: $(xcode-select -p)"
fi

# ── 2. Homebrew ──────────────────────────────────────────────────────────────
step "Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  echo "  Downloading and installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew installed"
else
  ok "Homebrew already installed: $(brew --version | head -1)"
fi

# ── 3. Oh My Zsh ─────────────────────────────────────────────────────────────
step "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "  Downloading and installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already installed"
fi

# ── 4. Apps via Brewfile ─────────────────────────────────────────────────────
step "Installing apps via Brewfile (this takes a while)..."
echo "  Running: brew bundle install --file=$DOTFILES/Brewfile"
if brew bundle install --file="$DOTFILES/Brewfile"; then
  ok "All Brewfile packages installed"
else
  warn "Some packages failed — re-run 'brew bundle install --file=~/code/dotfiles/Brewfile' after fixing network issues"
fi

# ── 4. Symlink dotfiles via stow ─────────────────────────────────────────────
step "Linking dotfiles..."
echo "  Creating required directories..."
mkdir -p ~/.config
mkdir -p ~/.claude
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "  Running stow..."
if stow -t ~ home --verbose 2>&1; then
  ok "Stow completed"
else
  warn "Stow had conflicts — some files may already exist. Check output above."
fi
echo "  Symlinking .claude files..."
ln -sfv "$DOTFILES/home/.claude/settings.json" ~/.claude/settings.json
ln -sfv "$DOTFILES/home/.claude/CLAUDE.md"     ~/.claude/CLAUDE.md
ok "Dotfiles linked"

# ── 5. Tmux plugins via TPM ──────────────────────────────────────────────────
step "Installing tmux plugins..."
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
# Note: tmux.conf must use run '~/.config/tmux/plugins/tpm/tpm' to match this path
if [ ! -d "$TPM_DIR" ]; then
  echo "  Cloning TPM into $TPM_DIR..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM cloned"
else
  ok "TPM already installed"
fi
echo "  Installing tmux plugins non-interactively..."
if "$TPM_DIR/bin/install_plugins"; then
  ok "Tmux plugins installed"
else
  warn "TPM plugin install failed — open tmux and press prefix+I to install manually"
fi

# ── 6. Git identity ──────────────────────────────────────────────────────────
step "Configuring git..."
git config --global user.name  "Talmage Potts"
git config --global user.email "klavierplayer23@gmail.com"
ok "Git identity set: Talmage Potts <klavierplayer23@gmail.com>"

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
