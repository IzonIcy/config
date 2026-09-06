# Dotfiles

My personal configuration files for macOS development.

## Quick Setup (new machine)

```bash
git clone https://github.com/IzonIcy/config.git ~/.dotfiles
cd ~/.dotfiles
./install.fish
exec fish
```

## What's Included

| Tool | Config Location | Purpose |
|------|----------------|---------|
| **git** | `git/config` | Aliases, delta diff, signed commits |
| **ghostty** | `ghostty/config` | Terminal (Catppuccin Mocha, ligatures, splits) |
| **starship** | `starship/starship.toml` | Prompt (Catppuccin, git status, dir, langs) |
| **fish** | `fish/config.fish` | Shell (atuin, zoxide, eza, mise, abbreviations) |
| **mise** | `mise/config.toml` | Tool versions (node, bun, rust, python) |
| **nvim** | `nvim/` | Neovim (lazy.nvim, LSP, DAP, Catppuccin) |

## Requirements

- [mise](https://mise.jdx.dev/) — tool version manager
- [fish](https://fishshell.com/) — shell
- [ghostty](https://ghostty.org/) — terminal
- [starship](https://starship.rs/) — prompt
- [atuin](https://atuin.sh/) — shell history
- [zoxide](https://github.com/ajeetdsouza/zoxide) — directory jumping
- [eza](https://github.com/eza-community/eza) — modern ls
- [neovim](https://neovim.io/) — editor

Install via Homebrew:
```bash
brew install mise fish ghostty starship atuin zoxide eza neovim
```

## Post-Install

1. Restart shell: `exec fish`
2. Run `:Lazy sync` in nvim to install plugins
3. Run `mise install` if tools weren't installed automatically

## Structure

```
.config/
├── install.fish          # Bootstrap script
├── git/
├── ghostty/
├── starship/
├── fish/
│   ├── config.fish       # Main config (sources conf.d/*)
│   ├── conf.d/           # Modular configs
│   └── functions/        # Custom functions
├── mise/
├── nvim/
│   ├── init.lua          # Entry point
│   └── lua/
│       ├── config/       # Core config (options, mappings, theme)
│       └── plugins/      # Plugin specs
└── ...
```

## Fish Startup Timer

Every interactive shell shows startup time:
```
fish startup: 42ms
```
Yellow if > 100ms.

## Neovim Startup

~84ms (headless). Run benchmark:
```bash
nvim --startuptime /tmp/startup.log --headless -c "quit"
tail -5 /tmp/startup.log
```