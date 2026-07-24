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
| `--with-clipsync` | Install + enable the ClipSync clipboard-sync daemon |
| `--no-desktop` | `--server` only: don't install a desktop environment |
| `--dry-run` | Print actions without performing them |

## Packages

| Package | Contents | Installed on |
|---|---|---|
| `terminal` | `.zshrc`, `.p10k.zsh`, tmux, ghostty, atuin, lazygit, worktrunk, ccstatusline | all |
| `nvim` | LazyVim config | all |
| `git` | `.gitconfig`, global gitignore, `gh` config | all |
| `claude` | Claude Code `settings.json`, `CLAUDE.md`, `herdr-push-status` | all |
| `ssh` | `~/.ssh/config` (never keys) | all |
| `mac` | Hammerspoon, Karabiner | macOS only |

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
with whatever happened to be on the machine. Commit before running it.

## Manual steps after install

The installer prints these, but for reference:

- `gh auth login`
- `atuin login`
- `sudo tailscale up`
- Linux: log out and back in so the `docker` group applies
- Linux: create `~/.secrets` if any project needs `DATABASE_URL` etc.
- macOS: add secrets to Keychain, sign into the App Store, re-run `brew bundle install` for MAS apps
