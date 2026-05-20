#!/bin/bash
# Talmage's Bootstrap Script
# Works on: macOS, Ubuntu/Debian Linux
#
# Usage on a fresh machine:
#   git clone https://github.com/talmagepotts/dotfiles.git ~/code/dotfiles
#   cd ~/code/dotfiles && chmod +x install.sh && ./install.sh

set -uo pipefail

DOTFILES="$HOME/code/dotfiles"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step()   { echo -e "\n${GREEN}==> $1${NC}"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
warn()   { echo -e "  ${YELLOW}⚠${NC}  $1"; }
manual() { echo -e "  ${YELLOW}[MANUAL]${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; }

# ── Detect OS ────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
elif [[ -f /etc/os-release ]]; then
  source /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* || "$ID" == "debian" ]]; then
    OS="ubuntu"
  else
    fail "Unsupported Linux distro: $ID. This script targets Ubuntu/Debian."
    exit 1
  fi
else
  fail "Unsupported OS: $OSTYPE"
  exit 1
fi
echo -e "${GREEN}Detected OS: $OS${NC}"

# ── 1. Mac: Xcode Command Line Tools ─────────────────────────────────────────
if [[ "$OS" == "mac" ]]; then
  step "Checking Xcode Command Line Tools..."
  if ! xcode-select -p &>/dev/null; then
    echo "  Installing Xcode CLT..."
    xcode-select --install
    warn "Finish the Xcode CLT install, then re-run this script."
    exit 1
  else
    ok "Xcode CLT already installed: $(xcode-select -p)"
  fi
fi

# ── 2. Package manager & core packages ───────────────────────────────────────
if [[ "$OS" == "mac" ]]; then
  step "Installing Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "  Downloading and installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
  else
    ok "Homebrew already installed: $(brew --version | head -1)"
  fi

  step "Installing apps via Brewfile (this takes a while)..."
  echo "  Running: brew bundle install --file=$DOTFILES/Brewfile"
  if brew bundle install --file="$DOTFILES/Brewfile"; then
    ok "All Brewfile packages installed"
  else
    warn "Some packages failed — re-run 'brew bundle install --file=~/code/dotfiles/Brewfile' after fixing issues"
  fi

elif [[ "$OS" == "ubuntu" ]]; then
  step "Updating apt and installing core packages..."
  sudo apt-get update -qq
  sudo apt-get install -y \
    build-essential \
    curl \
    direnv \
    git \
    git-filter-repo \
    git-lfs \
    nodejs \
    npm \
    postgresql \
    python3 \
    python3-pip \
    stow \
    tmux \
    zsh
  ok "Core apt packages installed"

  # Atuin: use the official installer (not in apt)
  if ! command -v atuin &>/dev/null; then
    step "Installing atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    ok "atuin installed"
  else
    ok "atuin already installed"
  fi
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

# Powerlevel10k (brew handles this on Mac; manual clone on Linux)
if [[ "$OS" == "ubuntu" ]]; then
  P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ ! -d "$P10K_DIR" ]; then
    step "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    ok "Powerlevel10k installed"
  else
    ok "Powerlevel10k already installed"
  fi
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

# ── 7. Set default shell to zsh ──────────────────────────────────────────────
if [[ "$SHELL" != *"zsh"* ]]; then
  step "Setting default shell to zsh..."
  if [[ "$OS" == "ubuntu" ]]; then
    sudo chsh -s "$(which zsh)" "$USER"
  else
    chsh -s "$(which zsh)"
  fi
  ok "Default shell set to zsh (takes effect on next login)"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "=================================================="
echo " Done! A few manual steps left:"
echo "=================================================="

if [[ "$OS" == "mac" ]]; then
  manual "Add secrets to Keychain (syncs via iCloud Keychain if enabled):"
  manual "  security add-generic-password -s dotfiles -a DATABASE_URL -w '<value>'"
  manual "  security add-generic-password -s dotfiles -a SUPABASE_ACCESS_TOKEN -w '<value>'"
  manual "SSH key: ssh-keygen -t ed25519 -C 'klavierplayer23@gmail.com'"
  manual "Add SSH key to GitHub: cat ~/.ssh/id_ed25519.pub | pbcopy → github.com/settings/keys"
  manual "Add SSH key to each server: ssh-copy-id teapot@jarvis (iris, atlas, etc.)"
  manual "Sign into App Store, then re-run: brew bundle install (for MAS apps)"
  manual "Tailscale: open app → sign in with your account"
  manual "Raycast: open it → sign in → enable cloud sync"
  manual "Sign into: Arc, Cursor, GitHub Desktop, Obsidian, etc."
elif [[ "$OS" == "ubuntu" ]]; then
  manual "SSH key: ssh-keygen -t ed25519 -C 'klavierplayer23@gmail.com'"
  manual "Add SSH key to GitHub: cat ~/.ssh/id_ed25519.pub → github.com/settings/keys"
  manual "Add SSH key to each server: ssh-copy-id teapot@jarvis (iris, atlas, etc.)"
  manual "Install Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
fi
manual "Run: gh auth login"
manual "Run: atuin login"
