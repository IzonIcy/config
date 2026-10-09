# Aliases ported from the zsh setup. zsh `alias ls=eza ...` is not valid fish:
# fish aliases cannot contain spaces in the expansion, so these use `abbr`,
# which expands in place and keeps completions working on the expanded form.

if status is-interactive
    if command -q eza
        abbr --add --global ls 'eza --icons=always'
        abbr --add --global ll 'eza --long --all --icons=always --group-directories-first'
        abbr --add --global tree 'eza --tree --level=3 --icons=always -I .git'
        abbr --add --global dtree 'eza --tree --level=3 --only-dirs --icons=always -I .git'
    end

    if command -q bat
        abbr --add --global cat 'bat --theme=ansi'
    end

    if command -q rg
        abbr --add --global grep 'rg'
    end

    if command -q lazygit
        abbr --add --global lg 'lazygit'
    end

    if command -q fastfetch
        abbr --add --global f 'fastfetch'
    end

    abbr --add --global gs 'git status'
    abbr --add --global ga 'git add .'
    abbr --add --global glog 'git log --oneline --graph --all'
    abbr --add --global vim 'nvim'
    abbr --add --global c 'clear'
    abbr --add --global e 'exit'

    abbr --add --global gc 'git commit -m'

    abbr --add --global .config 'cd $HOME/.config'
    abbr --add --global github 'cd $HOME/Documents/Github'
    abbr --add --global izon 'cd "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Izon Icy"'
end
