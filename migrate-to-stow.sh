#!/bin/bash
# One-time migration: restructures dotfiles to use stow
# Run from anywhere: bash ~/code/dotfiles/migrate-to-stow.sh

set -e
DOTFILES="$HOME/code/dotfiles"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
step()  { echo -e "\n${GREEN}==> $1${NC}"; }
warn()  { echo -e "${YELLOW}[skip]${NC} $1"; }
die()   { echo -e "${RED}[error]${NC} $1"; exit 1; }

cd "$DOTFILES"

# ── Sanity check ─────────────────────────────────────────────────────────────
[ -d "$DOTFILES" ] || die "Dotfiles not found at $DOTFILES"

# ── 1. Create stow package structure ─────────────────────────────────────────
step "Creating home/ stow package..."
mkdir -p home/.config

# ── 2. Move files in (skip if already moved) ─────────────────────────────────
step "Moving dotfiles into home/..."

move() {
  local src="$1" dst="$2"
  if [ -e "$src" ] || [ -L "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    mv "$src" "$dst"
    echo "  moved: $src → $dst"
  else
    warn "$src already moved or missing"
  fi
}

move "$DOTFILES/.zshrc"                    "$DOTFILES/home/.zshrc"
move "$DOTFILES/.p10k.zsh"                 "$DOTFILES/home/.p10k.zsh"
move "$DOTFILES/.gitconfig"                "$DOTFILES/home/.gitconfig"
move "$DOTFILES/nvim"                      "$DOTFILES/home/.config/nvim"
move "$DOTFILES/karabiner"                 "$DOTFILES/home/.config/karabiner"
move "$DOTFILES/ghostty"                   "$DOTFILES/home/.config/ghostty"
move "$DOTFILES/hammerspoon"               "$DOTFILES/home/.hammerspoon"

# tmux lives inside terminal/.config/tmux/
if [ -d "$DOTFILES/terminal/.config/tmux" ]; then
  move "$DOTFILES/terminal/.config/tmux"   "$DOTFILES/home/.config/tmux"
  rm -rf "$DOTFILES/terminal"
else
  warn "terminal/.config/tmux already moved or missing"
fi

# ── 3. Remove old symlinks ────────────────────────────────────────────────────
step "Removing old symlinks..."

remove_symlink() {
  local link="$1"
  if [ -L "$link" ]; then
    rm "$link"
    echo "  removed symlink: $link"
  else
    warn "not a symlink (skipping): $link"
  fi
}

remove_symlink ~/.zshrc
remove_symlink ~/.p10k.zsh
remove_symlink ~/.gitconfig
remove_symlink ~/.hammerspoon
remove_symlink ~/.config/nvim
remove_symlink ~/.config/karabiner
remove_symlink ~/.config/tmux
remove_symlink ~/.config/ghostty
remove_symlink ~/.claude/settings.json
remove_symlink ~/.claude/CLAUDE.md
remove_symlink ~/.config/gh/config.yml
remove_symlink ~/.ssh/config

# ── 4. Remove any real files that would conflict with stow ───────────────────
step "Clearing conflicting real files..."
# stow won't overwrite real files — only symlinks and dirs. Remove known conflicts.
while IFS= read -r conflict; do
  target="$HOME/${conflict#home/}"
  if [ -f "$target" ] && [ ! -L "$target" ]; then
    rm "$target"
    # remove parent dir if now empty
    rmdir "$(dirname "$target")" 2>/dev/null || true
    echo "  cleared real file: $target"
  fi
done < <(find home -type f | sed 's|^home/||')

# ── 5. Stow it ────────────────────────────────────────────────────────────────
step "Running stow..."
stow -t ~ home

# stow won't create individual file symlinks inside dirs that have lots of
# non-stow content (like ~/.claude). Handle those manually.
step "Symlinking files inside busy directories..."
ln -sf "$DOTFILES/home/.claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/home/.claude/CLAUDE.md"     ~/.claude/CLAUDE.md

# ── 6. Verify ─────────────────────────────────────────────────────────────────
step "Verifying symlinks..."
ok=true
check() {
  if [ -e "$1" ] || [ -L "$1" ]; then
    echo "  ✓ $1"
  else
    echo -e "  ${RED}✗ $1 — missing!${NC}"
    ok=false
  fi
}
check ~/.zshrc
check ~/.p10k.zsh
check ~/.gitconfig
check ~/.hammerspoon
check ~/.config/nvim
check ~/.config/karabiner
check ~/.config/tmux
check ~/.config/ghostty
check ~/.claude/settings.json
check ~/.claude/CLAUDE.md
check ~/.config/gh/config.yml
check ~/.ssh/config

echo ""
if $ok; then
  echo -e "${GREEN}Migration complete! All dotfiles are now stow-managed.${NC}"
  echo "From now on, to re-link everything on a new Mac: stow -t ~ home"
else
  echo -e "${RED}Some symlinks are missing — check output above.${NC}"
fi
