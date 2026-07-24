#!/usr/bin/env bash
# Talmage's Bootstrap Script
# Works on: macOS, Ubuntu/Debian Linux
#
# Usage on a fresh machine:
#   git clone https://github.com/talmagepotts/dotfiles.git ~/code/dotfiles
#   cd ~/code/dotfiles && chmod +x install.sh && ./install.sh [ROLE] [OPTIONS]
#
# Roles (pick one; auto-detected if omitted):
#   --workstation   Full setup with a desktop that starts at boot.  [Linux default when a DM is present]
#   --server        Headless-first: boots to a console, desktop started on demand.
#   --mac           macOS setup via Homebrew.                       [default on Darwin]
#
# Options:
#   --with-clipsync   Install the ClipSync clipboard-sync daemon (needs a desktop).
#   --no-desktop      Server role only: skip installing a desktop environment entirely.
#   --dry-run         Print what would happen without changing anything.
#   -h, --help        Show this help.
#
# The server role is what a Home Assistant box or similar always-on machine
# wants: nothing graphical runs until you ask for it, so the idle footprint
# stays small, but `desktop-start` is one command away when you want to plug it
# into a TV.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# $USER is not set in every environment this might run in (containers, cron,
# some non-login SSH sessions), and `set -u` turns that into a hard failure
# halfway through the install. Ask the system instead.
USER_NAME="${USER:-$(id -un)}"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

step()   { echo -e "\n${GREEN}==> $1${NC}"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
warn()   { echo -e "  ${YELLOW}⚠${NC}  $1"; }
manual() { echo -e "  ${YELLOW}[MANUAL]${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; }
skip()   { echo -e "  ${BLUE}·${NC} $1"; }

DRY_RUN=0
run() {
  if (( DRY_RUN )); then
    echo -e "  ${BLUE}[dry-run]${NC} $*"
    return 0
  fi
  "$@"
}

# try: run a command and report honestly. Prints the success message only if the
# command actually succeeded, and a warning with the exit code if it did not.
# Exists because a plain `run cmd; ok "done"` claims success unconditionally —
# which is how you end up believing lingering is enabled when it silently failed.
try() {
  local success_msg="$1"; shift
  if run "$@"; then
    ok "$success_msg"
    return 0
  else
    local code=$?
    warn "FAILED (exit $code): $*"
    return $code
  fi
}

# setup_intel_vaapi: enable hardware video decode on an Intel iGPU.
#
# Worth doing on any box that will drive a screen: it moves H.264/HEVC/VP9
# decoding off the CPU, which is the difference between smooth 4K YouTube and a
# pegged processor. Runs only when an Intel display device is actually present,
# so it is a no-op on machines without one.
#
# Note this is deliberately Intel-only. A machine can have a discrete card that
# is useless for this — an old NVIDIA Kepler card, say, has no VP9 decode at all
# and no supported driver on current Ubuntu, while the Intel iGPU beside it does
# everything needed. Check which GPU actually owns the HDMI port before assuming
# the discrete card is the better one.
setup_intel_vaapi() {
  command -v lspci &>/dev/null || return 0
  if ! lspci -nn 2>/dev/null | grep -iE "vga|3d|display" | grep -qi intel; then
    skip "No Intel GPU detected — skipping VA-API setup"
    return 0
  fi

  step "Enabling Intel hardware video decode (VA-API)..."
  try "VA-API drivers installed" \
    sudo apt-get install -y intel-media-va-driver-non-free vainfo

  # Access to /dev/dri/renderD* is granted to the active seat by logind ACLs,
  # which covers a graphical login — but not headless use over ssh (ffmpeg
  # transcodes, container workloads). Group membership covers both.
  if ! id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx render; then
    try "Added $USER_NAME to render/video groups" \
      sudo usermod -aG render,video "$USER_NAME"
  else
    ok "$USER_NAME already in the render group"
  fi
}

usage() { sed -n '2,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

# ── Parse arguments ──────────────────────────────────────────────────────────
ROLE=""
WITH_CLIPSYNC=0
NO_DESKTOP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workstation)   ROLE="workstation" ;;
    --server)        ROLE="server" ;;
    --mac)           ROLE="mac" ;;
    --with-clipsync) WITH_CLIPSYNC=1 ;;
    --no-desktop)    NO_DESKTOP=1 ;;
    --dry-run)       DRY_RUN=1 ;;
    -h|--help)       usage ;;
    *) fail "Unknown option: $1"; echo "Run with --help for usage."; exit 1 ;;
  esac
  shift
done

# ── Detect OS ────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
elif [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "$ID" == "ubuntu" || "${ID_LIKE:-}" == *"debian"* || "$ID" == "debian" ]]; then
    OS="ubuntu"
  else
    fail "Unsupported Linux distro: $ID. This script targets Ubuntu/Debian."
    exit 1
  fi
else
  fail "Unsupported OS: $OSTYPE"
  exit 1
fi

# Default the role from the OS if the caller did not pick one.
if [[ -z "$ROLE" ]]; then
  if [[ "$OS" == "mac" ]]; then ROLE="mac"; else ROLE="workstation"; fi
fi

if [[ "$ROLE" == "mac" && "$OS" != "mac" ]]; then
  fail "--mac given but this is not macOS."; exit 1
fi
if [[ "$ROLE" != "mac" && "$OS" == "mac" ]]; then
  fail "--$ROLE is a Linux role but this is macOS."; exit 1
fi

echo -e "${GREEN}OS: $OS   Role: $ROLE${NC}"
(( DRY_RUN )) && echo -e "${BLUE}Dry run — no changes will be made.${NC}"

# ── 1. Mac: Xcode Command Line Tools ─────────────────────────────────────────
if [[ "$OS" == "mac" ]]; then
  step "Checking Xcode Command Line Tools..."
  if ! xcode-select -p &>/dev/null; then
    echo "  Installing Xcode CLT..."
    run xcode-select --install
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
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
  else
    ok "Homebrew already installed: $(brew --version | head -1)"
  fi

  step "Installing apps via Brewfile (this takes a while)..."
  if run brew bundle install --file="$DOTFILES/Brewfile"; then
    ok "All Brewfile packages installed"
  else
    warn "Some packages failed — re-run 'brew bundle install --file=$DOTFILES/Brewfile' after fixing issues"
  fi

  # Symlink p10k into oh-my-zsh themes so ZSH_THEME="powerlevel10k/powerlevel10k" works
  P10K_LINK="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d /opt/homebrew/share/powerlevel10k && ! -e "$P10K_LINK" ]]; then
    run mkdir -p "$(dirname "$P10K_LINK")"
    run ln -sf /opt/homebrew/share/powerlevel10k "$P10K_LINK"
    ok "Powerlevel10k linked into oh-my-zsh themes"
  fi

elif [[ "$OS" == "ubuntu" ]]; then
  step "Updating apt and installing core packages..."
  run sudo apt-get update -qq
  # Kept deliberately in sync with what actually runs on these machines.
  # pnpm/bun/postgresql were removed: they were aspirational and unused —
  # install them per-project instead.
  try "Core apt packages installed" sudo apt-get install -y \
    bat \
    build-essential \
    ca-certificates \
    curl \
    direnv \
    eza \
    fd-find \
    ffmpeg \
    fzf \
    git \
    git-filter-repo \
    git-lfs \
    gnupg \
    htop \
    inotify-tools \
    jq \
    mosh \
    nodejs \
    npm \
    python3 \
    python3-pip \
    ripgrep \
    rsync \
    stow \
    tmux \
    unzip \
    zoxide \
    zsh

  # bat is installed as 'batcat' and fd as 'fdfind' on Ubuntu — symlink to expected names
  run mkdir -p "$HOME/.local/bin"
  [[ -f /usr/bin/batcat ]] && run ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
  [[ -f /usr/bin/fdfind ]] && run ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
  ok "bat and fd symlinked to ~/.local/bin"

  # ── Docker ────────────────────────────────────────────────────────────────
  # From Docker's own apt repo, not Ubuntu's — the distro package lags badly and
  # omits the compose/buildx plugins.
  if ! command -v docker &>/dev/null; then
    step "Installing Docker..."
    run sudo install -m 0755 -d /etc/apt/keyrings
    if (( ! DRY_RUN )); then
      curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
        | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
      sudo chmod a+r /etc/apt/keyrings/docker.asc
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
      sudo apt-get update -qq
    fi
    run sudo apt-get install -y \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
    ok "Docker installed"
  else
    ok "Docker already installed: $(docker --version 2>/dev/null || echo present)"
  fi

  # Run docker without sudo. Requires a re-login (or `newgrp docker`) to take effect.
  if ! id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx docker; then
    step "Adding $USER_NAME to the docker group..."
    try "Added to docker group — log out and back in for this to take effect" \
      sudo usermod -aG docker "$USER_NAME"
  else
    ok "$USER_NAME already in the docker group"
  fi

  # ── Tailscale ─────────────────────────────────────────────────────────────
  if ! command -v tailscale &>/dev/null; then
    step "Installing Tailscale..."
    try "Tailscale installed — run 'sudo tailscale up' to join your tailnet" \
      sh -c "curl -fsSL https://tailscale.com/install.sh | sh"
  else
    ok "Tailscale already installed"
  fi

  # Neovim: apt version is outdated; install latest from GitHub releases
  if ! command -v nvim &>/dev/null; then
    step "Installing neovim..."
    if (( ! DRY_RUN )); then
      curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
      sudo tar -xf /tmp/nvim.tar.gz -C /opt/
      sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
      rm /tmp/nvim.tar.gz
    fi
    ok "neovim installed"
  else
    ok "neovim already installed: $(nvim --version | head -1)"
  fi

  # GitHub CLI
  if ! command -v gh &>/dev/null; then
    step "Installing GitHub CLI..."
    if (( ! DRY_RUN )); then
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      sudo apt-get update -qq && sudo apt-get install -y gh
    fi
    ok "GitHub CLI installed"
  else
    ok "GitHub CLI already installed"
  fi

  # lazygit
  if ! command -v lazygit &>/dev/null; then
    step "Installing lazygit..."
    if (( ! DRY_RUN )); then
      LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*')
      curl -Lo /tmp/lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz"
      tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
      sudo install /tmp/lazygit /usr/local/bin
      rm /tmp/lazygit /tmp/lazygit.tar.gz
    fi
    ok "lazygit installed"
  else
    ok "lazygit already installed"
  fi

  # Atuin: use the official installer (not in apt)
  if ! command -v atuin &>/dev/null; then
    step "Installing atuin..."
    # --non-interactive is required, not optional. Without it the installer
    # probes for a terminal with `exec 3</dev/tty`; when there is no controlling
    # terminal (ssh without -t, CI, any automated run) that redirection is a
    # fatal error in a POSIX shell, so the script dies silently having installed
    # nothing — and still exits 0. The flag skips the probe entirely.
    try "atuin installed" \
      sh -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive"
  else
    ok "atuin already installed"
  fi

  # uv — Python package/venv manager
  if ! command -v uv &>/dev/null; then
    step "Installing uv..."
    try "uv installed" sh -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
  else
    ok "uv already installed"
  fi

  # rustup — also provides cargo, which installs worktrunk below
  if ! command -v rustup &>/dev/null; then
    step "Installing rustup..."
    try "rustup installed (stable toolchain included)" \
      sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
  else
    ok "rustup already installed: $(rustup --version 2>/dev/null | head -1)"
  fi
fi

# ── 3. Cross-platform CLI tooling ────────────────────────────────────────────
step "Installing Claude Code and friends..."

if ! command -v claude &>/dev/null; then
  try "Claude Code installed" sh -c "curl -fsSL https://claude.ai/install.sh | bash"
else
  ok "Claude Code already installed"
fi

# ccstatusline — referenced by the statusLine block in claude/.claude/settings.json
if ! command -v ccstatusline &>/dev/null; then
  # Point npm's global prefix at ~/.local so `npm install -g` does not need
  # root. A stock Ubuntu npm writes to /usr/local/lib/node_modules, which fails
  # with EACCES for a normal user; installing under sudo instead would leave
  # root-owned files in the user's tree, which is worse.
  if command -v npm &>/dev/null; then
    NPM_PREFIX="$(npm config get prefix 2>/dev/null)"
    if [[ "$NPM_PREFIX" != "$HOME"* ]]; then
      run npm config set prefix "$HOME/.local"
      ok "npm global prefix set to ~/.local (no sudo needed for -g installs)"
    fi
    try "ccstatusline installed" npm install -g ccstatusline
  else
    warn "npm not found — install ccstatusline later with: npm install -g ccstatusline"
  fi
else
  ok "ccstatusline already installed"
fi

# worktrunk (`wt`) — the gwc/gwcp shell functions and the tmux prefix+g binding
# both depend on this. Without it those are dead keys.
if ! command -v wt &>/dev/null; then
  # shellcheck disable=SC1091
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  if command -v cargo &>/dev/null; then
    try "worktrunk installed" cargo install worktrunk
  else
    warn "cargo not on PATH — install worktrunk later with: cargo install worktrunk"
  fi
else
  ok "worktrunk already installed"
fi

# ── 4. Oh My Zsh ─────────────────────────────────────────────────────────────
step "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  run sh -c 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already installed"
fi

# Powerlevel10k (brew handles this on Mac; manual clone on Linux)
if [[ "$OS" == "ubuntu" ]]; then
  P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ ! -d "$P10K_DIR" ]; then
    step "Installing Powerlevel10k theme..."
    try "Powerlevel10k installed" \
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  else
    ok "Powerlevel10k already installed"
  fi
fi

# ── 5. Symlink dotfiles via stow ─────────────────────────────────────────────
step "Linking dotfiles..."
run mkdir -p ~/.config ~/.claude ~/.local/bin ~/.ssh
run chmod 700 ~/.ssh

# Which stow packages this machine gets. Every role takes the shell/git/editor
# core; mac-only and clipboard packages are additive.
PACKAGES=(terminal nvim git claude ssh)
[[ "$ROLE" == "mac" ]] && PACKAGES+=(mac)

echo "  Packages: ${PACKAGES[*]}"
# --adopt moves any pre-existing real file into the repo, then git checkout
# restores the committed version — this turns "file already exists" conflicts
# into clean symlinks without hand-deleting anything.
run stow --adopt -t ~ "${PACKAGES[@]}" --verbose 2>&1
run git -C "$DOTFILES" checkout -- .
ok "Dotfiles linked"

# ── 6. Tmux plugins via TPM ──────────────────────────────────────────────────
step "Installing tmux plugins..."
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  try "TPM cloned" git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  ok "TPM already installed"
fi

# Actually install the plugins rather than telling the user to press prefix+I.
# tmux.conf pulls in catppuccin, sessionx, floax and friends; until those exist
# tmux comes up completely unstyled, which looks exactly like "the config didn't
# load". TPM ships a non-interactive installer, but it reads plugin declarations
# from a running server, so start a throwaway session first.
if [ -d "$TPM_DIR/bin" ] && command -v tmux &>/dev/null; then
  if (( DRY_RUN )); then
    echo -e "  ${BLUE}[dry-run]${NC} $TPM_DIR/bin/install_plugins"
  else
    tmux new-session -d -s _tpm_install 2>/dev/null || true
    if "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1; then
      ok "tmux plugins installed ($(find "$HOME/.config/tmux/plugins" -maxdepth 1 -mindepth 1 -type d | wc -l) total)"
    else
      warn "Some tmux plugins failed — open tmux and press prefix+I to retry"
    fi
    tmux kill-session -t _tpm_install 2>/dev/null || true
  fi
fi

# ── 7. Git identity ──────────────────────────────────────────────────────────
step "Configuring git..."
run git config --global user.name  "Talmage Potts"
run git config --global user.email "klavierplayer23@gmail.com"
ok "Git identity set: Talmage Potts <klavierplayer23@gmail.com>"

# ── 8. Default shell ─────────────────────────────────────────────────────────
if [[ "${SHELL:-}" != *"zsh"* ]]; then
  step "Setting default shell to zsh..."
  # Resolve zsh first: passing an empty -s to chsh would blank the login shell.
  ZSH_PATH="$(command -v zsh || true)"
  if [[ -z "$ZSH_PATH" ]]; then
    warn "zsh not found on PATH — skipping. Re-run this script once zsh is installed."
  elif [[ "$OS" == "ubuntu" ]]; then
    try "Default shell set to zsh (takes effect on next login)" \
      sudo chsh -s "$ZSH_PATH" "$USER_NAME"
  else
    try "Default shell set to zsh (takes effect on next login)" \
      chsh -s "$ZSH_PATH"
  fi
fi

# ── 9. Linux: desktop policy + long-running user services ────────────────────
# Everything below drives systemd. Test for a *running* systemd, not just the
# systemctl binary — container images ship the binary while PID 1 is something
# else, and every call then fails with "Failed to connect to bus".
if [[ "$OS" == "ubuntu" && ! -d /run/systemd/system ]]; then
  warn "systemd is not running (PID 1 is something else) — skipping desktop policy, lingering, and clipsync setup"
elif [[ "$OS" == "ubuntu" ]]; then
  # Lingering lets `systemd --user` units (and detached tmux sessions) survive
  # after you log out. On a server-role box there is no desktop session holding
  # the user manager open, so without this everything dies at logout.
  step "Enabling user lingering (keeps tmux/agents alive after logout)..."
  if [[ -e "/var/lib/systemd/linger/$USER_NAME" ]]; then
    ok "Lingering already enabled for $USER_NAME"
  else
    try "Lingering enabled for $USER_NAME" \
      sudo loginctl enable-linger "$USER_NAME"
  fi

  if [[ "$ROLE" == "server" ]]; then
    step "Configuring on-demand desktop (server role)..."
    if (( NO_DESKTOP )); then
      skip "--no-desktop given; not installing a desktop environment"
    else
      if ! dpkg -s xfce4 &>/dev/null; then
        echo "  Installing XFCE (started manually, not at boot)..."
        try "XFCE installed" sudo apt-get install -y xfce4 xfce4-goodies lightdm
      else
        ok "XFCE already installed"
      fi
      setup_intel_vaapi
    fi

    # Boot to a text console. The desktop becomes something you start, not
    # something that always runs — which is the whole point for a box whose day
    # job is Home Assistant.
    if [[ "$(systemctl get-default)" != "multi-user.target" ]]; then
      try "Default boot target set to multi-user.target (console)" \
        sudo systemctl set-default multi-user.target
    else
      ok "Already booting to multi-user.target"
    fi

    if systemctl is-enabled lightdm &>/dev/null; then
      try "lightdm disabled at boot" \
        sudo systemctl disable lightdm
    else
      ok "lightdm already disabled at boot"
    fi

    # Convenience wrappers so you never have to remember the systemctl commands.
    step "Installing desktop-start / desktop-stop helpers..."
    if (( ! DRY_RUN )); then
      cat > "$HOME/.local/bin/desktop-start" <<'EOF'
#!/usr/bin/env bash
# Start the graphical session on demand. Boot stays headless; this brings up
# lightdm (and with it XFCE) until you stop it or reboot.
set -euo pipefail
if systemctl is-active --quiet lightdm; then
  echo "Desktop already running."
else
  sudo systemctl start lightdm
  echo "Desktop started. Stop it again with: desktop-stop"
fi
EOF
      cat > "$HOME/.local/bin/desktop-stop" <<'EOF'
#!/usr/bin/env bash
# Stop the graphical session and hand the RAM/GPU back.
set -euo pipefail
sudo systemctl stop lightdm
echo "Desktop stopped."
EOF
      chmod +x "$HOME/.local/bin/desktop-start" "$HOME/.local/bin/desktop-stop"
    fi
    ok "desktop-start / desktop-stop installed to ~/.local/bin"

  elif [[ "$ROLE" == "workstation" ]]; then
    step "Desktop policy (workstation role)..."
    ok "Leaving boot target as-is ($(systemctl get-default))"
    setup_intel_vaapi
  fi

  # ── ClipSync ──────────────────────────────────────────────────────────────
  if (( WITH_CLIPSYNC )); then
    step "Setting up ClipSync..."
    if [[ ! -x "$HOME/.local/bin/clipsyncd" ]]; then
      warn "clipsyncd binary not found at ~/.local/bin/clipsyncd"
      manual "Copy it from a machine that has it, e.g.:"
      manual "  scp iris:~/.local/bin/clipsyncd ~/.local/bin/clipsyncd && chmod +x ~/.local/bin/clipsyncd"
    else
      ok "clipsyncd binary present"
    fi
    # The unit is COPIED, never stowed. `systemctl disable` deletes symlinks it
    # finds in the unit search path (it reads them as enablement links), which
    # would silently unlink the file from this repo. See services/README.md.
    run mkdir -p "$HOME/.config/systemd/user"
    run cp "$DOTFILES/services/clipsync.service" "$HOME/.config/systemd/user/clipsync.service"
    if (( ! DRY_RUN )); then
      systemctl --user daemon-reload 2>/dev/null || true
      systemctl --user enable clipsync 2>/dev/null || true
    fi
    ok "clipsync unit installed and enabled (starts with the desktop session)"
    if [[ ! -f "$HOME/.config/clipsync/daemon.json" ]]; then
      # Server URL comes from ~/.secrets — it is a tailnet address and this repo
      # is public. See .secrets.example.
      # shellcheck disable=SC1091
      [[ -f "$HOME/.secrets" ]] && source "$HOME/.secrets"
      if [[ -n "${CLIPSYNC_SERVER:-}" ]]; then
        manual "Register this device: clipsyncd login --server \$CLIPSYNC_SERVER"
      else
        manual "Set CLIPSYNC_SERVER in ~/.secrets, then: clipsyncd login --server \$CLIPSYNC_SERVER"
      fi
    fi
  fi
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
  manual "Sign into App Store, then re-run: brew bundle install (for MAS apps)"
  manual "Tailscale / Raycast: open each app → sign in"
else
  manual "Secrets: create ~/.secrets with 'export DATABASE_URL=...' etc (gitignored)"
  manual "SSH key: ssh-keygen -t ed25519 -C 'klavierplayer23@gmail.com'"
  manual "Add SSH key to GitHub: cat ~/.ssh/id_ed25519.pub → github.com/settings/keys"
  manual "Join tailnet: sudo tailscale up"
  manual "Log out and back in so the 'docker' group applies"
  if [[ "$ROLE" == "server" ]]; then
    manual "Start the desktop when you want it: desktop-start   (stop: desktop-stop)"
  fi
fi
manual "Machine-specific shell config goes in ~/.zshrc.local (untracked)"
manual "Run: gh auth login"
manual "Run: atuin login"
echo ""
echo "Verify the symlinks landed correctly with: $DOTFILES/check.sh"
