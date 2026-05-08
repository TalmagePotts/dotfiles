# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="$(gem env gemdir 2>/dev/null)/bin:$PATH"
alias lg='lazygit'
export PATH="$PATH:$HOME/code/exfunct"
alias dental_apps='cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Mysteries\ of\ God/dental_apps'
alias mobcode='cd ~/iCloud/Mob_Code'
export PATH="$PATH:$HOME/.pub-cache/bin"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
alias nst='npm run build && npm start'
alias st='pnpm tauri dev'
alias fix-safari='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'

# For zoxide
alias cd=z
alias tm="tmux new-session -A -s main"
# Fuzzy find and search contents
alias fs='rg --files --hidden --glob "!.git" | fzf --preview "bat --color=always {}"'
# Search file contents interactively
alias fsg='rg --line-number --color=always "" | fzf --ansi --preview "bat --color=always {1} --highlight-line {2}"'

# Simple: fuzzy find from current directory
alias ff='fd --type f | fzf --preview "bat --color=always {}"'

# With directory: fuzzy find from specified directory
ffd() {
  fd --type f . "${1:-.}" | fzf --preview "bat --color=always {}"
}

# Fuzzy find with initial query
ffq() {
  local query="$1"
  local dir="${2:-.}"
  fd "$query" "$dir" | fzf --preview "bat --color=always {}"
}

# Search multiple school directories
school() {
  local query="${1:-}"
  local dirs=(
    ~/iCloud/School
    ~/obsidian/School
  )
  
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] && fd "$query" "$dir"
  done | fzf --preview "bat --color=always {}"
}

# elixir-install paths (update versions after reinstalling elixir-install on a new Mac)
export PATH=$HOME/.elixir-install/installs/otp/28.1/bin:$PATH
export PATH=$HOME/.elixir-install/installs/elixir/1.19.0-otp-28/bin:$PATH

eval "$(atuin init zsh)"
eval "$(zoxide init zsh)"

export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@14/bin:$PATH"

export CLAUDE_CODE_SUBAGENT_MODEL=claude-sonnet-4-6
export API_TIMEOUT_MS='3000000'

alias lg='lazygit'
alias tm="tmux new-session -A -s main"
alias cd=z
alias nst='npm run build && npm start'
alias st='pnpm tauri dev'
alias fix-safari='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias nix-switch='darwin-rebuild switch --flake $HOME/code/dotfiles/nix-darwin#talmage'
alias nix-config='nvim $HOME/code/dotfiles/nix-darwin/flake.nix'
alias inum='cd $HOME/code/Tutoring-Input/Input-Inumber && bun tauri dev'
alias dental_apps='cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Mysteries\ of\ God/dental_apps'
alias mobcode='cd ~/iCloud/Mob_Code'
alias clau="unset ANTHROPIC_AUTH_TOKEN && unset ANTHROPIC_BASE_URL && claude"

# Fuzzy find
alias fs='rg --files --hidden --glob "!.git" | fzf --preview "bat --color=always {}"'
alias fsg='rg --line-number --color=always "" | fzf --ansi --preview "bat --color=always {1} --highlight-line {2}"'
alias ff='fd --type f | fzf --preview "bat --color=always {}"'

ffd() { fd --type f . "${1:-.}" | fzf --preview "bat --color=always {}"; }
ffq() { fd "$1" "${2:-.}" | fzf --preview "bat --color=always {}"; }

school() {
  local query="${1:-}"
  local dirs=(~/iCloud/School ~/obsidian/School)
  for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] && fd "$query" "$dir"
  done | fzf --preview "bat --color=always {}"
}

gwd() {
    git worktree add -b "$1" "../$1" origin/dev && \
    cd "../$1" && \
    git branch --set-upstream-to=origin/dev
}

gw() {
    git worktree add -b "talmage/$1" ".worktrees/$1" && \
    cd ".worktrees/$1" && \
    if [[ -f "../../.envrc" ]]; then
        cp "../../.envrc" .env
        echo "Copied .envrc to worktree"
    fi && \
    git push -u origin "talmage/$1"
}

# Load secrets from macOS Keychain (synced via iCloud, never stored in plaintext)
_secret() { security find-generic-password -s "dotfiles" -a "$1" -w 2>/dev/null; }
export DATABASE_URL="$(_secret DATABASE_URL)"
export SUPABASE_ACCESS_TOKEN="$(_secret SUPABASE_ACCESS_TOKEN)"
unset -f _secret


