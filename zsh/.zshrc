# =======================================
# Clean .zshrc — Powerlevel10k (no Oh My Zsh)
# + atuin, zoxide, fzf, mise, direnv
# =======================================

# 1️⃣ PATH (deduplicated)
typeset -U PATH path
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/curl/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.spicetify:$PATH"

# Env vars
export EDITOR=nvim
export VISUAL=nvim

# 2️⃣ Powerlevel10k instant prompt (keep near top)
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 3️⃣ Powerlevel10k theme (manual load, no Oh My Zsh)
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 4️⃣ Atuin — shell history sync + better Ctrl+r
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

# 5️⃣ Zoxide — smarter cd
eval "$(zoxide init zsh)"

# 6️⃣ FZF — keybindings (Ctrl+r history, Ctrl+t files, Alt+c dirs)
eval "$(fzf --zsh)"

# 7️⃣ Direnv — per-project env
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# 8️⃣ Mise — version manager (shims before Homebrew)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# 9️⃣ Zsh plugins (Homebrew-native, no omz)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# 🔟 History
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS

# 1️⃣1️⃣ Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# 1️⃣2️⃣ Aliases
alias ll="eza --long --all --icons=always --group-directories-first"
alias ls="eza --icons=always"
alias cat="bat --theme=ansi"
alias grep="rg"
alias lg="lazygit"
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias glog="git log --oneline --graph --all"
alias tree="eza --tree --level=3 --icons=always -I '.git'"
alias dtree="eza --tree --level=3 --only-dirs --icons=always -I '.git'"
alias c="clear"
alias e="exit"
alias vim="nvim"
alias f="fastfetch"
alias izon="cd \"$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Izon Icy\""
alias github="cd \"$HOME/Documents/Github\""
alias .config='cd "$HOME/.config"'

# Dropped from the zsh setup: nlo and nzo pointed at scripts that no longer
# exist, fman was a compgen one-liner that fzf covers directly, and sethvault
# pointed at an iCloud directory that is not present on this machine.

# EZA colors (standard terminal ANSI colors)
export EZA_COLORS="di=01;34:ln=01;36:ex=01;32:or=31;01:so=00;35:pi=01;33:bd=33;01:cd=33;01:im=01;35:vi=01;35:mu=00;36:lo=00;36:co=01;31:tm=00;90:do=01;34:*.py=01;32:*.js=01;32:*.ts=01;32:*.tsx=01;32:*.jsx=01;32:*.rs=01;32:*.go=01;32:*.rb=01;32:*.java=01;32:*.kt=01;32:*.scala=01;32:*.swift=01;32:*.c=01;32:*.cpp=01;32:*.h=01;32:*.lua=01;32:*.sh=01;32:*.zsh=01;32:*.fish=01;32:*.pl=01;32:*.hs=01;32:*.html=01;34:*.css=01;34:*.scss=01;34:*.sass=01;34:*.less=01;34:*.vue=01;34:*.svelte=01;34:*.astro=01;34:*.json=00;36:*.yaml=00;36:*.yml=00;36:*.toml=00;36:*.xml=00;36:*.ini=00;36:*.conf=00;36:*.env=00;90:*.gitignore=00;90:Makefile=01;33:Dockerfile=01;33:*.mk=01;33:Cargo.toml=01;33:package.json=01;33:go.mod=01;33"

# Bat theme
export BAT_THEME="ansi"

# FZF config
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_DEFAULT_OPTS="--height 50% --layout=reverse --border"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# GitHub token for MCP servers
if command -v gh &>/dev/null; then
  export GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token 2>/dev/null)
fi

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
# <<< grok installer <<<



# Vite+ bin (https://viteplus.dev)
. "/Users/ryanbahadori/.config/vite-plus/env"
