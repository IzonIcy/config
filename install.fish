#!/usr/bin/env fish
# Dotfiles bootstrap — run once on a new machine

set -l DOTFILES_DIR (realpath (dirname (status filename)))
set -l TARGET_DIR ~/.config

echo "Bootstrapping dotfiles from $DOTFILES_DIR → $TARGET_DIR"

# Configs to symlink
set -l configs \
    git \
    ghostty \
    starship \
    fish \
    mise \
    nvim

for c in $configs
    set -l src "$DOTFILES_DIR/$c"
    set -l dst "$TARGET_DIR/$c"

    if test -e "$dst"; and not test -L "$dst"
        echo "⚠ $dst exists and is not a symlink — skipping"
        continue
    end

    if test -L "$dst"
        set -l current (readlink "$dst")
        if test "$current" = "$src"
            echo "✓ $c already linked"
            continue
        else
            echo "↻ $c points elsewhere — relinking"
        end
    end

    ln -sf "$src" "$dst"
    echo "✓ Linked $c"
end

# Ensure fish completions dir exists
mkdir -p ~/.config/fish/completions

# Install mise tools if mise is available
if command -q mise
    echo "Installing mise tools..."
    mise install
else
    echo "mise not found — install it first: https://mise.jdx.dev/getting-started.html"
end

# Generate fish completions for tools that support it
if command -q mise
    mise completion fish > ~/.config/fish/completions/mise.fish
end
if command -q atuin
    atuin gen-completions --shell fish > ~/.config/fish/completions/atuin.fish
end
# zoxide completions are handled by `zoxide init fish` in config.fish
# eza doesn't have built-in completion generation

echo ""
echo "Done. Restart your shell or run: exec fish"