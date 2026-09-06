if status is-interactive
    set -g __fish_startup_start (date +%s%N | cut -c1-13)
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/ryanbahadori/.lmstudio/bin
# End of LM Studio CLI section



# Added by Antigravity CLI installer
set -gx PATH "/Users/ryanbahadori/.local/bin" $PATH

# Starship prompt
set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml
starship init fish | source

# bat follows the terminal ANSI palette (dark in Ghostty now)
set -gx BAT_THEME ansi

# Atuin shell history
if command -q atuin
    atuin init fish | source
end

# Mise dev tools
if command -q mise
    mise activate fish | source
end

# Eza (modern ls)
if command -q eza
    abbr -a l 'eza --icons --git --group-directories-first'
    abbr -a la 'eza --icons --git -la --group-directories-first'
    abbr -a lt 'eza --icons --tree --git'
end

# Zoxide (smart directory jumping)
if command -q zoxide
    zoxide init fish | source
end

# Git abbreviations
abbr -a gco 'git checkout'
abbr -a gst 'git status -s'
abbr -a gd 'git diff'
abbr -a gl 'git log --oneline --graph'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gc 'git commit -m'

# Docker compose
abbr -a dc 'docker compose'

# Fastfetch on shell start
function fish_greeting
    fastfetch
end

# Startup timer
if set -q __fish_startup_start
    set -l now (date +%s%N | cut -c1-13)
    set -l elapsed (math $now - $__fish_startup_start)
    if test $elapsed -gt 100
        set_color yellow
    else
        set_color green
    end
    echo "fish startup: $elapsed ms"
    set_color normal
end
