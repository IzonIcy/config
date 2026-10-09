# fzf keybindings. `fzf --fish` ships inside the fzf binary and honours the same
# FZF_* variables as the zsh setup, so the tuned previews carry over unchanged.
#
# Numbered 10- so it loads before atuin in config.fish. That is deliberate: fish
# sources conf.d before config.fish, and atuin binds ctrl-r on init, so loading
# fzf first means atuin wins ctrl-r for history search. In the zsh setup the
# order is reversed (atuin line 26, fzf line 33) and fzf wins. If you would
# rather have fzf on ctrl-r, rename this to 20-fzf.fish.

if command -q fzf
    set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"
    set -gx FZF_DEFAULT_OPTS "--height 50% --layout=reverse --border"
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always -n --line-range :500 {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'eza --icons=always --tree --color=always {} | head -200'"

    fzf --fish | source
end
