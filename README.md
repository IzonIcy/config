# Dotfiles

My personal configuration files for macOS development.

## Quick Setup (new machine)

```bash
git clone https://github.com/IzonIcy/config.git ~/.config
cd ~/.config
./install.fish
exec fish
```

## What's Included

| Tool          | Config Location            | Purpose                                         |
| ------------- | -------------------------- | ----------------------------------------------- |
| **aerospace** | `aerospace/aerospace.toml` | Tiling window manager and workspace bindings    |
| **atuin**     | `atuin/`                   | Shell history                                   |
| **btop**      | `btop/`                    | System monitor and themes                       |
| **fastfetch** | `fastfetch/`               | Shell greeting and system summary               |
| **git**       | `git/config`               | Aliases, delta diff, signed commits             |
| **gh**        | `gh/config.yml`            | GitHub CLI preferences and aliases              |
| **herdr**     | `herdr/`                   | Terminal workspace manager and plugins          |
| **karabiner** | `karabiner/karabiner.json` | Key remapping (Caps Lock as Esc / Ctrl)         |
| **ghostty**   | `ghostty/config`           | Terminal (default colors, ligatures, splits)    |
| **mole**      | `mole/`                    | Cleanup lists                                   |
| **opencode**  | `opencode/`                | Agent, skill, MCP, and formatter configuration  |
| **spicetify** | `spicetify/`               | Spotify themes and extensions                   |
| **fish**      | `fish/config.fish`         | Shell (atuin, zoxide, eza, mise, abbreviations) |
| **mise**      | `mise/config.toml`         | Tool versions (node, bun, rust, python)         |
| **nvim**      | `nvim/`                    | Separately owned Neovim configuration           |

## Requirements

- [mise](https://mise.jdx.dev/) — tool version manager
- [fish](https://fishshell.com/) — shell
- [ghostty](https://ghostty.org/) — terminal
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) — window manager
- [Karabiner-Elements](https://karabiner.pqrs.org/) — key remapping
- [atuin](https://atuin.sh/) — shell history
- [zoxide](https://github.com/ajeetdsouza/zoxide) — directory jumping
- [eza](https://github.com/eza-community/eza) — modern ls
- [neovim](https://neovim.io/) — editor

Install via Homebrew:

```bash
brew install mise fish ghostty atuin zoxide eza neovim
```

## Post-Install

1. Restart shell: `exec fish`
2. Run `:Lazy sync` in nvim to install plugins
3. Run `./install.fish --check-dependencies` to check installed tools
4. Run `./install.fish --install-tools` to install pinned Mise tools
5. Run `./install.fish --generate-completions` if completions are needed
6. Run `./install.fish --apply-defaults` to apply the macOS system preferences
7. Grant Karabiner-Elements Input Monitoring in System Settings > Privacy &
   Security > Input Monitoring. Without it the key mapping loads but does nothing.

## macOS Preferences

`macos/defaults.sh` holds the system preferences that make macOS behave like a
Linux workstation: smart quotes, smart dashes and autocorrect off, a 24-hour
clock, Finder showing file extensions and the path bar, reduced transparency,
full keyboard access, and an auto-hiding Dock.

The script only writes settings that differ from the macOS factory defaults, is
safe to re-run, and reports what it changed:

```bash
./install.fish --apply-defaults   # or: sh macos/defaults.sh
```

## Structure

```
.config/
├── install.fish          # Bootstrap script
├── git/
├── ghostty/
├── karabiner/
│   └── karabiner.json # Key remapping profile
├── fish/
│   ├── config.fish       # Main config (sources conf.d/*)
│   ├── conf.d/           # Modular configs
│   └── functions/        # Custom functions
├── macos/
│   └── defaults.sh    # macOS system preferences
├── mise/
├── nvim/
│   ├── init.lua          # Entry point
│   └── lua/
│       ├── config/       # Core config (options, mappings, theme)
│       └── plugins/      # Plugin specs
└── ...
```

This repository is the live `~/.config` directory. The installer checks the
configuration directories in place and links AeroSpace to
`~/.aerospace.toml`. Runtime state, caches, and generated completions are not
source configuration.

## Fish Startup Timer

Set `FISH_STARTUP_TIMER=1` to show startup time for an interactive shell:

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
