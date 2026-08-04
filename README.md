# Dotfiles

Config for every machine I use, laid out as [GNU Stow](https://www.gnu.org/software/stow/)
packages so each machine links only the parts it needs.

## Install

```sh
git clone git@github.com:talmagepotts/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles && chmod +x install.sh && ./install.sh [ROLE]
```

Add `--dry-run` to any invocation to see what it would do without touching the machine.

### Roles

| Role | What it is | Desktop |
|---|---|---|
| `--mac` | macOS via Homebrew + Brewfile | n/a (default on Darwin) |
| `--workstation` | Full Linux dev box | Starts at boot; boot target untouched |
| `--server` | Headless-first Linux box | Installed but **off at boot** — start it with `desktop-start` |

`--server` is for machines whose day job is a service (Home Assistant, a build
runner) but which you occasionally want to plug into a TV. It sets the boot
target to `multi-user.target` and disables `lightdm`, so nothing graphical is
resident until you ask for it. Two helpers get installed:

```sh
desktop-start   # bring up lightdm + XFCE now
desktop-stop    # tear it down, hand back the RAM
```

Pass `--no-desktop` to skip installing a desktop environment at all.

### Options

| Flag | Effect |
|---|---|
| `--with-apps` | macOS: also install the coding apps (see tiers below) |
| `--with-clipsync` | Install + enable the ClipSync clipboard-sync daemon |
| `--no-desktop` | `--server` only: don't install a desktop environment |
| `--allow-dirty` | Link dotfiles even with uncommitted changes here — **discards them** (see below) |
| `--dry-run` | Print actions without performing them |

`install.sh` exits non-zero if any step failed, and prints a summary of exactly
which ones at the end. Individual failures don't abort the run — one missing
package shouldn't cost you the other twenty steps — so check the tail.

### macOS package tiers

**A plain `./install.sh` is lean.** It installs the terminal toolchain and the
few GUI apps that are load-bearing — and nothing else. Heavy things are opt-in,
because most installs are servers, VMs and fresh boxes that will never open
Xcode.

| Tier | File | Installed by | Contents |
|---|---|---|---|
| Lean | `Brewfile` | always | Terminal tools (`stow`, `rg`, `fd`, `bat`, `fzf`, `zoxide`, `jq`, `gh`, `lazygit`, `nvim`, `tmux`, `atuin`, …), Ghostty, Hammerspoon, Obsidian, Tailscale, Moonlight, Nerd Font |
| Apps | `Brewfile.apps` | `--with-apps` | Cursor, Codex, Arc, Raycast, SF Symbols, `xcode-build-server`, niche CLI (neomutt, w3m, pass, nmap, PDF tools), **and every Mac App Store app incl. Xcode** |
| Heavy | `Brewfile.optional` | manual only | Android Studio, Godot, Audacity, Postgres, cmake, system Python |

```sh
./install.sh                                    # lean
./install.sh --with-apps                        # lean + coding apps
brew bundle install --file=Brewfile.optional    # the heavy stuff, later
```

Two rules keep the tiers honest:

- **Anything the stowed dotfiles depend on lives in the lean tier.** Ghostty,
  Hammerspoon and the Nerd Font look like GUI bloat but aren't optional —
  Ghostty is the terminal, Hammerspoon's config is in the `mac` package, and
  p10k renders as garbage without the font.
- **All App Store entries live in the apps tier**, so the lean install never
  needs an Apple ID. Signing into the App Store is the step that fails on a
  fresh machine; the lean path doesn't have it.

## Packages

| Package | Contents | Installed on |
|---|---|---|
| `terminal` | `.zshrc`, `.p10k.zsh`, tmux, ghostty, atuin, lazygit, worktrunk, ccstatusline | all |
| `nvim` | LazyVim config | all |
| `git` | `.gitconfig`, global gitignore, `gh` config | all |
| `claude` | Claude Code `settings.json`, `CLAUDE.md`, `herdr-push-status` | all |
| `ssh` | `~/.ssh/config` (never keys) | all |
| `mac` | Hammerspoon | macOS only |

Stow one by hand with `stow -t ~ <package>`.

`services/` holds systemd user units. Those are **copied**, not stowed — see
[services/README.md](services/README.md) for why that distinction matters.

## Per-machine config

Anything true of exactly one machine does **not** belong in this repo. Three
escape hatches, all gitignored:

| File | For |
|---|---|
| `~/.zshrc.local` | Shell config for one host — VM helpers, host IPs, one-off PATH entries. Sourced near the end of `.zshrc`. |
| `~/.secrets` | Linux secrets (`export DATABASE_URL=...`). macOS reads the Keychain instead and ignores this file. |
| `~/.config/clipsync/daemon.json` | ClipSync device identity + auth token. Per-device by definition; recreated by `clipsyncd login`. |

`.zshrc` gates macOS-only aliases behind `$OSTYPE` and globs for installed
toolchain versions rather than pinning them, so the same file works everywhere.

## Checking for drift

```sh
./check.sh              # packages this machine should have
./check.sh terminal git # specific packages
```

This exists because of a failure mode that hides well: a tracked file ends up
as a plain **copy** in `$HOME` instead of a symlink — a partial stow, a manual
`cp`, an editor that replaces rather than writes in place. Everything keeps
working, so nothing looks broken, but your edits stop reaching git and the repo
quietly goes stale. `check.sh` exits non-zero when it finds one, and tells you
whether the copy still matches the repo or has diverged.

It compares *resolved* paths rather than testing for a symlink on each file,
because stow folds whole directories into a single link when it can — a
correctly linked file often has no symlink of its own.

### A warning about `stow --adopt`

`install.sh` uses `stow --adopt`, which resolves "file already exists"
conflicts by moving the existing file **into this repo** and then linking it.
`install.sh` immediately runs `git checkout -- .` to restore the committed
version, so the net effect is normally harmless.

But if you have uncommitted changes in the repo, `--adopt` will overwrite them
with whatever happened to be on the machine, and the `git checkout -- .` that
follows reverts the **whole worktree** — including edits that had nothing to do
with stow.

`install.sh` refuses to link when the tree is dirty and tells you what would be
lost, rather than trusting you to have committed first. Stash or commit, or pass
`--allow-dirty` to throw the changes away deliberately.

## Manual steps after install

The installer prints these, but for reference:

- `gh auth login`
- `atuin login`
- `sudo tailscale up`
- Linux: log out and back in so the `docker` group applies
- Linux: create `~/.secrets` if any project needs `DATABASE_URL` etc.
- macOS: add secrets to Keychain, sign into the App Store, re-run `brew bundle install` for MAS apps
