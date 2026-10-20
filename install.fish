#!/usr/bin/env fish
# Check and bootstrap configuration stored directly in ~/.config.

set -l DOTFILES_DIR (realpath (dirname (status filename)))
set -l TARGET_DIR "$HOME/.config"
set -l install_tools false
set -l generate_completions false
set -l check_dependencies false
set -l apply_defaults false

for arg in $argv
    switch $arg
        case --install-tools
            set install_tools true
        case --generate-completions
            set generate_completions true
        case --check-dependencies
            set check_dependencies true
        case --apply-defaults
            set apply_defaults true
        case '*'
            echo "Unknown option: $arg" >&2
            echo "Usage: ./install.fish [--install-tools] [--generate-completions] [--check-dependencies] [--apply-defaults]" >&2
            exit 2
    end
end

if not test -d "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
end

echo "Checking configuration in $DOTFILES_DIR"

function check_config --argument-names name source_root target_root
    set -l src "$source_root/$name"
    set -l dst "$target_root/$name"

    if not test -e "$src"; and not test -L "$src"
        echo "✗ Missing: $src" >&2
        return 1
    end

    if test "$src" = "$dst"
        echo "✓ $name"
        return 0
    end

    if test -L "$dst"
        set -l current (readlink "$dst")
        if test "$current" = "$src"
            echo "✓ $name already linked"
        else
            echo "! $dst points to $current, expected $src" >&2
            return 1
        end
        return 0
    end

    if test -e "$dst"
        echo "! $dst exists and is not a symlink" >&2
        return 1
    end

    if ln -s "$src" "$dst"
        echo "✓ Linked $name"
    else
        echo "✗ Failed to link $name" >&2
        return 1
    end
end

# Tools that read their config from $HOME instead of XDG_CONFIG_HOME. The real
# file lives in this repo; only a symlink lives in $HOME.
function link_home --argument-names name source target
    if not test -e "$source"
        echo "✗ Missing: $source" >&2
        return 1
    end

    if test -L "$target"
        set -l current (readlink "$target")
        if test "$current" = "$source"
            echo "✓ $name already linked"
            return 0
        end
        echo "! $target points to $current, expected $source" >&2
        return 1
    end

    if test -e "$target"
        echo "! $target exists and is not a symlink" >&2
        return 1
    end

    if ln -s "$source" "$target"
        echo "✓ Linked $name"
    else
        echo "✗ Failed to link $name" >&2
        return 1
    end
end

set -l configs \
    atuin \
    btop \
    cava \
    fastfetch \
    fish \
    gh \
    ghostty \
    git \
    herdr \
    karabiner \
    mise \
    mole \
    opencode \
    spicetify

set -l failed false
for config in $configs
    check_config $config "$DOTFILES_DIR" "$TARGET_DIR"; or set failed true
end

# AeroSpace reads ${XDG_CONFIG_HOME:-~/.config}/aerospace/aerospace.toml and
# ~/.aerospace.toml, and calls the config ambiguous when both exist, even when
# one is a symlink to the other. Keep only the XDG path.
set -l aerospace_src "$DOTFILES_DIR/aerospace/aerospace.toml"
set -l aerospace_dst "$HOME/.aerospace.toml"
if test -e "$aerospace_dst" || test -L "$aerospace_dst"
    echo "! $aerospace_dst makes the AeroSpace config ambiguous, remove it" >&2
    set failed true
else if not test -e "$aerospace_src"
    echo "✗ Missing: $aerospace_src" >&2
    set failed true
end

# zsh and git read their config from the home directory, not from
# XDG_CONFIG_HOME, so they need the same explicit link AeroSpace does above.
link_home zshrc "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"; or set failed true
link_home zshenv "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"; or set failed true
link_home gitignore_global "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"; or set failed true

if $failed
    echo "Configuration check failed. No tools or completions were changed." >&2
    exit 1
end

if $check_dependencies
    set -l required_commands fish mise atuin
    set -l optional_commands zoxide eza fastfetch aerospace borders ghostty herdr mole spicetify

    for command_name in $required_commands
        if not command -q $command_name
            echo "✗ Missing required command: $command_name" >&2
            set failed true
        end
    end

    for command_name in $optional_commands
        if not command -q $command_name
            echo "! Missing optional command: $command_name" >&2
        end
    end
end

if $failed
    echo "Dependency check failed. No tools or completions were changed." >&2
    exit 1
end

if $install_tools
    if command -q mise
        echo "Installing Mise tools..."
        mise install; or set failed true
    else
        echo "! mise not found, cannot install tools" >&2
        set failed true
    end
end

if $failed
    echo "Tool installation failed. Completions were not generated." >&2
    exit 1
end

if $apply_defaults
    if test -x "$DOTFILES_DIR/macos/defaults.sh"
        sh "$DOTFILES_DIR/macos/defaults.sh"; or set failed true
    else
        echo "! macos/defaults.sh is not executable, skipping" >&2
    end
end

if $generate_completions
    if not mkdir -p "$TARGET_DIR/fish/completions"
        echo "✗ Could not create Fish completions directory" >&2
        exit 1
    end

    if command -q mise
        set -l output "$TARGET_DIR/fish/completions/mise.fish"
        set -l temporary "$output.tmp.$fish_pid"
        if mise completion fish > "$temporary"; and test -s "$temporary"
            mv "$temporary" "$output"
        else
            rm -f "$temporary"
            echo "✗ Could not generate Mise completions" >&2
            set failed true
        end
    else
        echo "! mise not found, skipping Mise completions" >&2
    end

    if command -q atuin
        set -l output "$TARGET_DIR/fish/completions/atuin.fish"
        set -l temporary "$output.tmp.$fish_pid"
        if atuin gen-completions --shell fish > "$temporary"; and test -s "$temporary"
            mv "$temporary" "$output"
        else
            rm -f "$temporary"
            echo "✗ Could not generate Atuin completions" >&2
            set failed true
        end
    else
        echo "! atuin not found, skipping Atuin completions" >&2
    end
end

if $failed
    echo "Configuration check failed." >&2
    exit 1
end

echo "Configuration check passed."
