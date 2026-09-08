# Added by LM Studio CLI (lms)
if test -d "$HOME/.lmstudio/bin"
    fish_add_path --global "$HOME/.lmstudio/bin"
end
# End of LM Studio CLI section

# Added by Antigravity CLI installer
if test -d "$HOME/.local/bin"
    fish_add_path --global "$HOME/.local/bin"
end

set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
set -gx BAT_THEME ansi

if status is-interactive
    if set -q FISH_STARTUP_TIMER
        set -g __fish_startup_start (date +%s%N | cut -c1-13)
    end

    # Starship prompt
    if command -q starship
        starship init fish | source
    end

    # Atuin shell history
    if command -q atuin
        atuin init fish | source
    end

    # Mise dev tools, including Rust
    if command -q mise
        mise activate fish | source
    end

    # Eza (modern ls)
    if command -q eza
        abbr --add --global l 'eza --icons --git --group-directories-first'
        abbr --add --global la 'eza --icons --git -la --group-directories-first'
        abbr --add --global lt 'eza --icons --tree --git'
    end

    # Zoxide (smart directory jumping)
    if command -q zoxide
        zoxide init fish | source
    end

    # Git abbreviations
    abbr --add --global gco 'git checkout'
    abbr --add --global gst 'git status -s'
    abbr --add --global gd 'git diff'
    abbr --add --global gl 'git log --oneline --graph'
    abbr --add --global gp 'git push'
    abbr --add --global gpl 'git pull'
    abbr --add --global gc 'git commit -m'

    # Docker compose
    abbr --add --global dc 'docker compose'

    # Fastfetch on shell start
    function fish_greeting
        if command -q fastfetch
            fastfetch
        end
    end

    # Opt-in startup timer. It measures config loading, not fish_greeting.
    if set -q FISH_STARTUP_TIMER; and set -q __fish_startup_start
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
end
