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
#   --with-apps       macOS: also install the coding apps (Cursor, Codex, Xcode,
#                     Arc, Raycast) from Brewfile.apps. Off by default — a plain
#                     run installs only the lean terminal-tool baseline.
#   --with-clipsync   Install the ClipSync clipboard-sync daemon (needs a desktop).
#   --no-desktop      Server role only: skip installing a desktop environment entirely.
#   --allow-dirty     Link dotfiles even with uncommitted changes here (discards them).
#   --dry-run         Print what would happen without changing anything.
#   -h, --help        Show this help.
#
# macOS package tiers:
#   Brewfile           lean baseline — terminal tools, Ghostty, Obsidian,
#                      Tailscale, Moonlight. No App Store login needed. Always.
#   Brewfile.apps      coding apps + Xcode + niche CLI.        --with-apps
#   Brewfile.optional  Android Studio, Godot, Postgres, …      manual only:
#                      brew bundle install --file=Brewfile.optional
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

# Everything that failed, collected so the run ends with a summary instead of a
# wall of scrollback you have to re-read. The script deliberately does not use
# `set -e` — one missing package should not abandon the other twenty steps — so
# this is the only thing standing between a partial install and a silent one.
FAILURES=()

record_failure() { FAILURES+=("$1"); }

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
    record_failure "$success_msg (exit $code)"
    return $code
  fi
}

# need: abort when a command the rest of the script genuinely cannot work
# without is missing. Reserved for hard dependencies — most things should
# degrade to a warning via try() instead.
need() {
  local cmd="$1" why="$2"
  command -v "$cmd" &>/dev/null && return 0
  (( DRY_RUN )) && { warn "$cmd not installed — a real run would stop here ($why)"; return 1; }
  fail "Required command '$cmd' not found — $why"
  echo ""
  echo "  Nothing was linked. Install it and re-run this script:"
  if [[ "${OS:-}" == "mac" ]]; then
    echo "    brew install $cmd"
  else
    echo "    sudo apt-get install -y $cmd"
  fi
  exit 1
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

# Print the header comment block — everything from line 2 up to the first line
# that is not a comment. Reads the block dynamically rather than hard-coding
# `sed -n '2,23p'`, which silently prints the wrong thing the moment the header
# grows or shrinks by a line.
usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
  exit 0
}

# ── Parse arguments ──────────────────────────────────────────────────────────
ROLE=""
WITH_CLIPSYNC=0
WITH_APPS=0
NO_DESKTOP=0
ALLOW_DIRTY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workstation)   ROLE="workstation" ;;
    --server)        ROLE="server" ;;
    --mac)           ROLE="mac" ;;
    --with-clipsync) WITH_CLIPSYNC=1 ;;
    --with-apps)     WITH_APPS=1 ;;
    --no-desktop)    NO_DESKTOP=1 ;;
    --allow-dirty)   ALLOW_DIRTY=1 ;;
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
    # The installer does not put brew on PATH for the shell that invoked it, so
    # locate it by hand exactly once. Apple Silicon and Intel use different
    # prefixes; hard-coding /opt/homebrew works right up until it doesn't.
    for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [[ -x "$_brew" ]] && { eval "$("$_brew" shellenv)"; break; }
    done
    unset _brew
    if command -v brew &>/dev/null; then
      ok "Homebrew installed: $(brew --version | head -1)"
    else
      fail "Homebrew install did not produce a working 'brew' — cannot continue."
      echo "  Install it manually from https://brew.sh and re-run this script."
      exit 1
    fi
  else
    ok "Homebrew already installed: $(brew --version | head -1)"
  fi

  # The lean baseline: terminal tools plus the few GUI apps that are
  # load-bearing. Deliberately contains no App Store entries, so this step does
  # not need an Apple ID and does not fail on a fresh machine.
  step "Installing the lean baseline via Brewfile..."
  if run brew bundle install --file="$DOTFILES/Brewfile"; then
    ok "Lean baseline installed"
  else
    warn "Some packages failed — re-run 'brew bundle install --file=$DOTFILES/Brewfile' after fixing issues"
    record_failure "brew bundle (lean baseline — some packages did not install)"
  fi

  if (( WITH_APPS )); then
    step "Installing coding apps via Brewfile.apps (Xcode is ~15GB — this takes a while)..."
    if run brew bundle install --file="$DOTFILES/Brewfile.apps"; then
      ok "Coding apps installed"
    else
      warn "Some apps failed — re-run 'brew bundle install --file=$DOTFILES/Brewfile.apps' after fixing issues"
      warn "The Mac App Store entries (Xcode, TestFlight, …) fail until you sign into the App Store."
      record_failure "brew bundle (Brewfile.apps — some apps did not install)"
    fi
  else
    skip "Coding apps skipped (Cursor, Codex, Xcode, Arc, Raycast) — add --with-apps for those"
  fi

  # Symlink p10k into oh-my-zsh themes so ZSH_THEME="powerlevel10k/powerlevel10k" works
  P10K_LINK="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  P10K_SRC="$(brew --prefix 2>/dev/null)/share/powerlevel10k"
  if [[ -d "$P10K_SRC" && ! -e "$P10K_LINK" ]]; then
    run mkdir -p "$(dirname "$P10K_LINK")"
    try "Powerlevel10k linked into oh-my-zsh themes" ln -sf "$P10K_SRC" "$P10K_LINK"
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
  [[ -f /usr/bin/batcat ]] && try "bat symlinked to ~/.local/bin" ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
  [[ -f /usr/bin/fdfind ]] && try "fd symlinked to ~/.local/bin"  ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"

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
    try "Docker installed" sudo apt-get install -y \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
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

  # These three install from upstream release tarballs rather than apt (the
  # distro packages lag badly). Each is wrapped in a function so `try` can
  # report the real exit status — as straight-line code under `if (( !
  # DRY_RUN ))` the trailing `ok` fired even when the download 404'd.
  #
  # Release assets are named by Go/Rust arch strings, not dpkg's, so translate
  # once here instead of hard-coding x86_64 and breaking on arm64 boxes.
  case "$(uname -m)" in
    x86_64|amd64) REL_ARCH="x86_64" ;;
    aarch64|arm64) REL_ARCH="arm64" ;;
    *) REL_ARCH="" ;;
  esac

  install_neovim() {
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${REL_ARCH}.tar.gz"
    local tmp; tmp="$(mktemp -d)" || return 1
    # Clean up the download even when a step below fails.
    trap 'rm -rf "$tmp"' RETURN
    curl -fLo "$tmp/nvim.tar.gz" "$url" || return 1
    sudo tar -xf "$tmp/nvim.tar.gz" -C /opt/ || return 1
    sudo ln -sf "/opt/nvim-linux-${REL_ARCH}/bin/nvim" /usr/local/bin/nvim
  }

  install_gh() {
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none || return 1
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null || return 1
    sudo apt-get update -qq && sudo apt-get install -y gh
  }

  install_lazygit() {
    local tmp; tmp="$(mktemp -d)" || return 1
    trap 'rm -rf "$tmp"' RETURN
    local version
    version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
      | grep -Po '"tag_name": "v\K[^"]*') || return 1
    [[ -n "$version" ]] || return 1
    curl -fLo "$tmp/lazygit.tar.gz" \
      "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_${REL_ARCH}.tar.gz" || return 1
    tar -xf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit || return 1
    sudo install "$tmp/lazygit" /usr/local/bin
  }

  # Neovim: apt version is outdated; install latest from GitHub releases
  if ! command -v nvim &>/dev/null; then
    step "Installing neovim..."
    if [[ -z "$REL_ARCH" ]]; then
      warn "Unrecognised architecture $(uname -m) — install neovim manually"
      record_failure "neovim (unsupported arch $(uname -m))"
    else
      try "neovim installed" install_neovim
    fi
  else
    ok "neovim already installed: $(nvim --version | head -1)"
  fi

  # GitHub CLI
  if ! command -v gh &>/dev/null; then
    step "Installing GitHub CLI..."
    try "GitHub CLI installed" install_gh
  else
    ok "GitHub CLI already installed"
  fi

  # lazygit
  if ! command -v lazygit &>/dev/null; then
    step "Installing lazygit..."
    if [[ -z "$REL_ARCH" ]]; then
      warn "Unrecognised architecture $(uname -m) — install lazygit manually"
      record_failure "lazygit (unsupported arch $(uname -m))"
    else
      try "lazygit installed" install_lazygit
    fi
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

fi

# ── 3. Cross-platform CLI tooling ────────────────────────────────────────────
# Everything here uses its own installer rather than apt/brew, so it runs the
# same way on both platforms. uv and rustup used to live in the Ubuntu-only
# branch, which meant a Mac silently got neither — and with no cargo, the
# `cargo install worktrunk` below was skipped too, leaving the gm/gwc/gwcp/
# wtclean shell functions and the tmux prefix+g binding as dead keys.

# uv — Python package/venv manager
if ! command -v uv &>/dev/null; then
  step "Installing uv..."
  try "uv installed" sh -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
else
  ok "uv already installed"
fi

# rustup — also provides cargo, which installs worktrunk below.
# Not the Homebrew `rustup` formula on Mac: that one no longer ships
# rustup-init and needs its own PATH entry, whereas this installer puts cargo
# in ~/.cargo/bin, which .zshrc already adds and this script already sources.
if ! command -v rustup &>/dev/null; then
  step "Installing rustup..."
  try "rustup installed (stable toolchain included)" \
    sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
else
  ok "rustup already installed: $(rustup --version 2>/dev/null | head -1)"
fi

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
    # Mac is exempt: Homebrew's prefix is already user-writable, so repointing
    # npm there fixes nothing and just splits global installs across two trees.
    if [[ "$OS" == "ubuntu" ]]; then
      NPM_PREFIX="$(npm config get prefix 2>/dev/null)"
      if [[ "$NPM_PREFIX" != "$HOME"* ]]; then
        try "npm global prefix set to ~/.local (no sudo needed for -g installs)" \
          npm config set prefix "$HOME/.local"
      fi
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
  # .zshrc sources $ZSH/oh-my-zsh.sh unconditionally, so a silent failure here
  # means every new shell starts with an error.
  try "Oh My Zsh installed" \
    sh -c 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
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

# Without stow nothing below this point does anything, and every later step
# (tmux plugins, p10k) reads config that would never have been linked. Fail
# loudly here rather than printing "Dotfiles linked" over an empty home dir.
need stow "install.sh links every dotfile with it"

# --adopt moves any pre-existing real file into the repo, then git checkout
# restores the committed version — this turns "file already exists" conflicts
# into clean symlinks without hand-deleting anything.
#
# That `git checkout -- .` is indiscriminate: it reverts the whole worktree, so
# any uncommitted edit sitting here when the script runs is destroyed along
# with the adopted files. Check first instead of relying on the README's
# "commit before running it".
if (( ! DRY_RUN )) && [[ -n "$(git -C "$DOTFILES" status --porcelain 2>/dev/null)" ]]; then
  if (( ALLOW_DIRTY )); then
    warn "Working tree is dirty and --allow-dirty was given — these changes will be discarded:"
    git -C "$DOTFILES" status --short | sed 's/^/      /'
  else
    fail "Working tree at $DOTFILES has uncommitted changes."
    git -C "$DOTFILES" status --short | sed 's/^/      /'
    echo ""
    echo "  Linking uses 'stow --adopt' followed by 'git checkout -- .', which would"
    echo "  discard all of the above. Commit or stash first:"
    echo "    git -C $DOTFILES stash"
    echo ""
    echo "  Or re-run with --allow-dirty to throw them away deliberately."
    exit 1
  fi
fi

if run stow --adopt -t ~ "${PACKAGES[@]}" --verbose 2>&1; then
  run git -C "$DOTFILES" checkout -- .
  ok "Dotfiles linked"
else
  fail "stow failed — dotfiles are NOT linked"
  record_failure "stow (dotfiles not linked)"
  # Adopted files are sitting in the repo now; put them back either way so the
  # tree is not left in a half-migrated state.
  run git -C "$DOTFILES" checkout -- .
fi

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
    # Kill the throwaway session even if install_plugins dies or the user hits
    # Ctrl-C, so a failed run does not leave a stray server behind.
    trap 'tmux kill-session -t _tpm_install 2>/dev/null || true' EXIT INT TERM
    if "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1; then
      ok "tmux plugins installed ($(find "$HOME/.config/tmux/plugins" -maxdepth 1 -mindepth 1 -type d | wc -l) total)"
    else
      warn "Some tmux plugins failed — open tmux and press prefix+I to retry"
      record_failure "tmux plugins (retry with prefix+I)"
    fi
    tmux kill-session -t _tpm_install 2>/dev/null || true
    trap - EXIT INT TERM
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
      if chmod +x "$HOME/.local/bin/desktop-start" "$HOME/.local/bin/desktop-stop"; then
        ok "desktop-start / desktop-stop installed to ~/.local/bin"
      else
        warn "Could not write desktop-start / desktop-stop to ~/.local/bin"
        record_failure "desktop-start / desktop-stop helpers"
      fi
    else
      ok "desktop-start / desktop-stop installed to ~/.local/bin"
    fi

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
if (( ${#FAILURES[@]} )); then
  echo " Finished with ${#FAILURES[@]} failure(s):"
  echo "=================================================="
  for f in "${FAILURES[@]}"; do fail "$f"; done
  echo ""
  echo " Everything else completed. Fix the above and re-run — the script is"
  echo " idempotent, so already-installed steps are skipped."
  echo ""
  echo "=================================================="
  echo " Manual steps:"
else
  echo " Done! A few manual steps left:"
fi
echo "=================================================="

if [[ "$OS" == "mac" ]]; then
  manual "Add secrets to Keychain (syncs via iCloud Keychain if enabled):"
  manual "  security add-generic-password -s dotfiles -a DATABASE_URL -w '<value>'"
  manual "  security add-generic-password -s dotfiles -a SUPABASE_ACCESS_TOKEN -w '<value>'"
  manual "SSH key: ssh-keygen -t ed25519 -C 'klavierplayer23@gmail.com'"
  manual "Add SSH key to GitHub: cat ~/.ssh/id_ed25519.pub | pbcopy → github.com/settings/keys"
  manual "Tailscale: open the app → sign in"
  if (( WITH_APPS )); then
    manual "Sign into the App Store, then re-run for the MAS apps (Xcode, TestFlight, …):"
    manual "  brew bundle install --file=$DOTFILES/Brewfile.apps"
    manual "Raycast: open the app → sign in"
  else
    manual "This was the lean install. Coding apps (Cursor, Codex, Xcode, Arc, Raycast):"
    manual "  brew bundle install --file=$DOTFILES/Brewfile.apps"
  fi
  manual "Heavy/per-project extras (Android Studio, Godot, Postgres):"
  manual "  brew bundle install --file=$DOTFILES/Brewfile.optional"
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

# Exit non-zero when anything failed. Without this the script always reported
# success, so a half-finished install looked identical to a clean one — both to
# a human skimming the tail and to anything running this unattended.
(( ${#FAILURES[@]} )) && exit 1
exit 0
