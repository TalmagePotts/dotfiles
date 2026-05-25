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

  # Symlink p10k into oh-my-zsh themes so ZSH_THEME="powerlevel10k/powerlevel10k" works
  P10K_LINK="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d /opt/homebrew/share/powerlevel10k && ! -e "$P10K_LINK" ]]; then
    mkdir -p "$(dirname "$P10K_LINK")"
    ln -sf /opt/homebrew/share/powerlevel10k "$P10K_LINK"
    ok "Powerlevel10k linked into oh-my-zsh themes"
  fi

elif [[ "$OS" == "ubuntu" ]]; then
  step "Updating apt and installing core packages..."
  sudo apt-get update -qq
  sudo apt-get install -y \
    bat \
    build-essential \
    curl \
    direnv \
    fd-find \
    fzf \
    git \
    git-filter-repo \
    git-lfs \
    nodejs \
    npm \
    postgresql \
    python3 \
    python3-pip \
    ripgrep \
    stow \
    tmux \
    zoxide \
    zsh
  ok "Core apt packages installed"

  # bat is installed as 'batcat' and fd as 'fdfind' on Ubuntu — symlink to expected names
  mkdir -p "$HOME/.local/bin"
  [[ -f /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
  [[ -f /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
  ok "bat and fd symlinked to ~/.local/bin"

  # Neovim: apt version is outdated; install latest from GitHub releases
  if ! command -v nvim &>/dev/null; then
    step "Installing neovim..."
    curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    sudo tar -xf /tmp/nvim.tar.gz -C /opt/
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    rm /tmp/nvim.tar.gz
    ok "neovim installed"
  else
    ok "neovim already installed: $(nvim --version | head -1)"
  fi

  # GitHub CLI
  if ! command -v gh &>/dev/null; then
    step "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update -qq && sudo apt-get install -y gh
    ok "GitHub CLI installed"
  else
    ok "GitHub CLI already installed"
  fi

  # lazygit
  if ! command -v lazygit &>/dev/null; then
    step "Installing lazygit..."
    LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
      | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm /tmp/lazygit /tmp/lazygit.tar.gz
    ok "lazygit installed"
  else
    ok "lazygit already installed"
  fi

  # Atuin: use the official installer (not in apt)
  if ! command -v atuin &>/dev/null; then
    step "Installing atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    ok "atuin installed"
  else
    ok "atuin already installed"
  fi

  # pnpm (official installer avoids npm global permission issues)
  if ! command -v pnpm &>/dev/null; then
    step "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | sh
    ok "pnpm installed"
  else
    ok "pnpm already installed"
  fi

  # bun
  if ! command -v bun &>/dev/null; then
    step "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
    ok "bun installed"
  else
    ok "bun already installed"
  fi

  # rustup
  if ! command -v rustup &>/dev/null; then
    step "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    ok "rustup installed (stable toolchain included)"
  else
    ok "rustup already installed: $(rustup --version)"
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
# --adopt moves existing files into the dotfiles repo, then git checkout restores the
# committed versions — this handles pre-existing files like .gitconfig or .p10k.zsh
stow --adopt -t ~ home --verbose 2>&1 || true
git -C "$DOTFILES" checkout -- .
ok "Stow completed"
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
  ok "TPM cloned — open tmux and press prefix+I to install plugins"
else
  ok "TPM already installed — open tmux and press prefix+I to install plugins"
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
  manual "Rust stable is installed; add more toolchains: rustup target add <target>"
fi
manual "Run: gh auth login"
manual "Run: atuin login"
