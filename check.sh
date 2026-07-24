#!/usr/bin/env bash
# Verify every tracked dotfile is actually symlinked back into this repo.
#
# This exists because of a real failure mode: files can end up as plain copies
# in $HOME instead of symlinks (a failed stow, a manual cp, an editor that
# replaces rather than writes in place). Everything keeps working, so nothing
# looks wrong — but edits stop reaching git, and the repo silently goes stale.
#
# Usage:
#   ./check.sh              # check the packages this machine should have
#   ./check.sh terminal git # check specific packages
#
# Exit code is non-zero if anything is wrong, so it works in CI or a pre-commit hook.

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

if [[ $# -gt 0 ]]; then
  PACKAGES=("$@")
else
  # systemd units live in services/ and are copied, not stowed — see
  # services/README.md — so they are deliberately not checked here.
  PACKAGES=(terminal nvim git claude ssh)
  [[ "$OSTYPE" == darwin* ]] && PACKAGES+=(mac)
fi

linked=0; copied=0; missing=0; foreign=0

for pkg in "${PACKAGES[@]}"; do
  pkgdir="$DOTFILES/$pkg"
  if [[ ! -d "$pkgdir" ]]; then
    echo -e "${RED}✗${NC} no such package: $pkg"
    (( foreign++ ))
    continue
  fi

  # Enumerate TRACKED files only, via git rather than find. Runtime state lands
  # inside package directories — TPM clones eleven tmux plugins into
  # terminal/.config/tmux/plugins — and those are gitignored, not ours to link.
  # Walking the filesystem counted them and buried the real signal under a
  # thousand lines of noise.
  while IFS= read -r -d '' relpath; do
    src="$DOTFILES/$relpath"
    rel="${relpath#"$pkg"/}"
    target="$HOME/$rel"

    # Files matching .stowrc's --ignore patterns are deliberately not linked.
    case "$(basename "$rel")" in
      README.md|.DS_Store) continue ;;
    esac

    if [[ ! -e "$target" ]]; then
      echo -e "${YELLOW}⚠${NC}  $rel is not present in \$HOME"
      (( missing++ ))
      continue
    fi

    # Compare resolved paths rather than testing -L on the leaf. Stow folds
    # whole directories into a single symlink when it can, so a correctly
    # linked file often has no symlink of its own — its *parent* is the link.
    # Testing -L on the file would call every one of those a stale copy.
    resolved="$(readlink -f "$target" 2>/dev/null)"
    src_resolved="$(readlink -f "$src" 2>/dev/null)"

    if [[ "$resolved" == "$src_resolved" ]]; then
      (( linked++ ))
    elif [[ -L "$target" ]]; then
      echo -e "${RED}✗${NC} $rel → symlink points outside the repo ($resolved)"
      (( foreign++ ))
    else
      if diff -q "$target" "$src" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC}  $rel is a COPY, not a symlink (contents match — safe to re-stow)"
      else
        echo -e "${RED}✗${NC} $rel is a COPY and has DIVERGED — diff before re-stowing:"
        echo "     diff $target $src"
      fi
      (( copied++ ))
    fi
  done < <(git -C "$DOTFILES" ls-files -z -- "$pkg")
done

echo ""
echo "Packages: ${PACKAGES[*]}"
echo -e "${GREEN}$linked linked${NC}  ${YELLOW}$copied copies${NC}  ${YELLOW}$missing missing${NC}  ${RED}$foreign wrong-target${NC}"

if (( copied || foreign )); then
  echo ""
  echo "Fix copies by re-stowing (adopts the file, then restores the committed version):"
  echo "  cd $DOTFILES && stow --adopt -t ~ ${PACKAGES[*]} && git checkout -- ."
  echo "Review 'git diff' after --adopt if anything showed as DIVERGED."
  exit 1
fi
(( missing )) && exit 1
exit 0
