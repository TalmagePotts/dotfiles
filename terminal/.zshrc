# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# Early-load p10k when installed via Homebrew (needed for instant prompt on Mac).
# Both prefixes are tested literally rather than shelling out to `brew --prefix`
# — this runs on every shell start, and a subprocess here is exactly the cost
# instant prompt exists to avoid. /opt/homebrew is Apple Silicon, /usr/local Intel.
for _p10k in /opt/homebrew /usr/local; do
  if [[ -f "$_p10k/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    source "$_p10k/share/powerlevel10k/powerlevel10k.zsh-theme"
    break
  fi
done
unset _p10k

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ── Platform detection ───────────────────────────────────────────────────────
# Used throughout this file to gate OS-specific config. One place to change.
if [[ "$OSTYPE" == darwin* ]]; then
  IS_MAC=1
else
  IS_MAC=0
fi

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# ── PATH: cross-platform ─────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/scripts:$PATH"
export PATH="$PATH:$HOME/code/exfunct"
export PATH="$PATH:$HOME/.pub-cache/bin"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
[[ -d "$HOME/.atuin/bin" ]] && export PATH="$HOME/.atuin/bin:$PATH"

# elixir-install puts each toolchain under a version directory. Glob for whatever
# is installed rather than pinning versions that go stale on every upgrade.
for _elixir_bin in "$HOME"/.elixir-install/installs/*/*/bin(N); do
  export PATH="$_elixir_bin:$PATH"
done
unset _elixir_bin

# ── PATH: macOS / Homebrew ───────────────────────────────────────────────────
if (( IS_MAC )); then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
  export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
  export PATH="/opt/homebrew/opt/postgresql@14/bin:$PATH"
  # `gem env` costs a subshell on every new shell and is only useful once ruby
  # is on PATH, so guard it rather than paying for a failure on Linux.
  if command -v gem >/dev/null 2>&1; then
    export PATH="$(gem env gemdir)/bin:$PATH"
  fi
fi

# ── Environment ──────────────────────────────────────────────────────────────
export CLAUDE_CODE_SUBAGENT_MODEL=claude-sonnet-4-6
export API_TIMEOUT_MS='3000000'
# CLAUDE_NTFY_TOPIC is intentionally NOT set here — an ntfy topic name is an
# unauthenticated capability (whoever knows it can read and post), and this repo
# is public. It comes from ~/.secrets, sourced further down. See .secrets.example.

# ── Aliases: cross-platform ──────────────────────────────────────────────────
alias lg='lazygit'
alias tm="tmux new-session -A -s main"
alias dev='tmux new-session -A -s main'
alias nst='npm run build && npm start'
alias st='pnpm tauri dev'
alias inum='cd $HOME/code/Tutoring-Input/Input-Inumber && bun tauri dev'
alias clau="unset ANTHROPIC_AUTH_TOKEN && unset ANTHROPIC_BASE_URL && claude"

# Fuzzy find
alias fs='rg --files --hidden --glob "!.git" | fzf --preview "bat --color=always {}"'
alias fsg='rg --line-number --color=always "" | fzf --ansi --preview "bat --color=always {1} --highlight-line {2}"'
alias ff='fd --type f | fzf --preview "bat --color=always {}"'

ffd() { fd --type f . "${1:-.}" | fzf --preview "bat --color=always {}"; }
ffq() { fd "$1" "${2:-.}" | fzf --preview "bat --color=always {}"; }

# Search across whichever note/school directories exist on this machine.
school() {
  local query="${1:-}"
  local dirs=(~/iCloud/School ~/obsidian/School)
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] && fd "$query" "$dir"
  done | fzf --preview "bat --color=always {}"
}

# ── Aliases: macOS only ──────────────────────────────────────────────────────
if (( IS_MAC )); then
  alias fix-safari='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
  alias nix-switch='darwin-rebuild switch --flake $HOME/code/dotfiles/nix-darwin#talmage'
  alias nix-config='nvim $HOME/code/dotfiles/nix-darwin/flake.nix'
  alias dental_apps='cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Mysteries\ of\ God/dental_apps'
  alias mobcode='cd ~/iCloud/Mob_Code'
fi

# ── Git worktree helpers ─────────────────────────────────────────────────────
gwd() {
    git worktree add -b "$1" "../$1" origin/dev && \
    cd "../$1" && \
    git branch --set-upstream-to=origin/dev
}

gw() {
    local name="$1"
    local branch="talmage/$name"
    git worktree add -b "$branch" ".worktrees/$name" || return 1
    cd ".worktrees/$name" || return 1
    if [[ -f "../../.envrc" ]]; then
        cp "../../.envrc" .env
        echo "Copied .envrc to worktree"
    fi
    git push -u origin "$branch" && \
        gh pr create --draft --title "$name" --body "" 2>/dev/null || true
}

# gm: merge current branch into main (overrides oh-my-zsh git plugin's `gm`
# alias for `git merge`, since worktree-based dev makes this the more useful default)
alias gm='wt merge main'

# gwc: create worktree via Worktrunk (hooks in ~/.config/worktrunk/config.toml
# handle .envrc copy, push+draft PR, and tmux+claude launch)
# Usage: gwc <branch-name>
gwc() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: gwc <branch-name>"
        return 1
    fi
    wt switch --create "talmage/$name"
}

# gwcp: pick a project from anywhere, cd into it, then gwc <feature-name>.
# Usage: gwcp (fzf-picks project, prompts for name) | gwcp <project> <name>
gwcp() {
    local project="$1" name="$2"
    if [[ -z "$project" ]]; then
        project=$(find ~/code -maxdepth 1 -mindepth 1 -type d ! -name dotfiles \
                -exec test -e '{}/.git' \; -print \
            | xargs -n1 basename | sort \
            | fzf --prompt="Project> ") || return 1
    fi
    [[ -z "$project" ]] && return 1
    cd ~/code/"$project" || return 1
    if [[ -z "$name" ]]; then
        read "name?Feature name: "
    fi
    [[ -z "$name" ]] && { echo "Aborted: no feature name"; return 1; }

    local picker_window
    [[ -n "$TMUX" ]] && picker_window=$(tmux display-message -p '#{window_id}')

    gwc "$name" || return 1

    # Close the disposable picker window the Ctrl-a g shortcut spawned for us —
    # the Worktrunk post-start hook already switched focus to the new session.
    if [[ -n "$GWCP_EPHEMERAL" && -n "$picker_window" ]]; then
        tmux kill-window -t "$picker_window" 2>/dev/null
    fi
}

# gwc-pr: push the current worktree's branch and open a draft PR.
# Opt-in — gwc no longer does this automatically, since local `wt merge main`
# is the default merge path and an auto-opened PR would go stale.
# Usage: gwc-pr (run from inside the worktree)
gwc-pr() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || { echo "Not in a git repo"; return 1; }
    git push -u origin "$branch" && \
        gh pr create --draft --title "$branch" --body "" --head "$branch"
}

# gwc-clean: bulk-remove worktrees/branches Worktrunk has verified are merged
# into the default branch (ancestor / tree-match / squash patch-id match) —
# replaces git-prune-merged, which trusted "remote branch gone" instead.
gwc-clean() {
    wt list --format=json --branches \
        | jq -r '.[] | select(.main_state=="integrated" or .main_state=="empty") | .branch' \
        | xargs -r -n1 wt remove
}

# ── Claude Code helpers ──────────────────────────────────────────────────────
# notify: send a push notification via ntfy.sh
# Usage: notify "message" ["title"] ["tags"]
notify() {
  local msg="$1"
  local title="${2:-Claude Code}"
  local tags="${3:-robot}"
  if [[ -z "${CLAUDE_NTFY_TOPIC:-}" ]]; then
    echo "notify: CLAUDE_NTFY_TOPIC not set — add it to ~/.secrets" >&2
    return 1
  fi
  curl -s --max-time 5 -H "Title: $title" -H "Tags: $tags" -d "$msg" \
    "ntfy.sh/$CLAUDE_NTFY_TOPIC" > /dev/null
}

# cc: run claude with elapsed-time notification on exit.
# Note: Claude hooks already notify mid-session and on Stop —
#       cc adds a final "process exited" ping with timing.
# Usage: cc [claude args...]
cc() {
  local start
  start=$(date +%s)
  claude "$@"
  local code=$?
  local elapsed=$(( $(date +%s) - start ))
  local mins=$(( elapsed / 60 ))
  local secs=$(( elapsed % 60 ))
  local dir
  dir=$(basename "$(pwd)")
  if [ $code -eq 0 ]; then
    notify "✅ Process exited cleanly in ${mins}m ${secs}s — $dir" "Claude Exited" "stopwatch"
  else
    notify "❌ Process crashed ($code) after ${mins}m ${secs}s — $dir" "Claude Crashed" "warning"
  fi
  return $code
}

# ccc: continue last claude session
ccc() { claude --continue "$@"; }

# ccr: pick and resume a past claude session
ccr() { claude --resume; }

# cc-loop: restart claude automatically if it exits, notify each cycle
# Usage: cc-loop "your prompt"
cc-loop() {
  local prompt="$1"
  if [ -z "$prompt" ]; then
    echo "Usage: cc-loop \"your prompt\""
    return 1
  fi
  local i=0
  while true; do
    i=$(( i + 1 ))
    echo "[cc-loop] Starting run #$i"
    claude "$prompt" || true
    notify "🔁 Claude exited (run #$i) — restarting in 10s — $(basename $(pwd))" "cc-loop" "arrows_counterclockwise"
    sleep 10
  done
}

# ── Secrets ──────────────────────────────────────────────────────────────────
# macOS keeps these in the Keychain (synced via iCloud, never stored in
# plaintext). Linux has no Keychain, so it reads ~/.secrets — gitignored and
# created by hand per machine. Guarding by platform matters: unguarded,
# `security` fails on Linux and exports these as empty strings, which breaks
# tools more confusingly than leaving them unset.
if (( IS_MAC )); then
  _secret() { security find-generic-password -s "dotfiles" -a "$1" -w 2>/dev/null; }
  export DATABASE_URL="$(_secret DATABASE_URL)"
  export SUPABASE_ACCESS_TOKEN="$(_secret SUPABASE_ACCESS_TOKEN)"
  unset -f _secret
elif [[ -f "$HOME/.secrets" ]]; then
  source "$HOME/.secrets"
fi

# ── Persistent tmux on remote login ──────────────────────────────────────────
# On an interactive SSH/mosh login (not local, not already in tmux), drop
# straight into a persistent session so agents keep running when the connection
# drops and reconnects resume instantly.
if [[ $- == *i* && -z "$TMUX" && ( -n "$SSH_CONNECTION" || -n "$SSH_TTY" || -n "$MOSH" ) ]] \
   && command -v tmux >/dev/null 2>&1; then
  tmux new-session -A -s main
fi

# ── Machine-local overrides ──────────────────────────────────────────────────
# Anything specific to one machine (VM helpers, host IPs, one-off PATH entries)
# lives here. Untracked by git — see README.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ── Tool init ────────────────────────────────────────────────────────────────
# zoxide insists on being initialized last (it warns loudly otherwise), and
# `alias cd=z` must come after its init so the alias wins.
command -v atuin  >/dev/null 2>&1 && eval "$(atuin init zsh)"
command -v wt     >/dev/null 2>&1 && eval "$(command wt config shell init zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
alias cd=z
