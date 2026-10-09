# Environment and tool defaults shared by every fish shell.

set -gx EDITOR nvim
set -gx VISUAL nvim

# eza colors, carried over verbatim from the zsh setup. Files are colored by
# extension and directories by type, matching the dark Ghostty palette.
set -gx EZA_COLORS "di=01;34:ln=01;36:ex=01;32:or=31;01:so=00;35:pi=01;33:bd=33;01:cd=33;01:im=01;35:vi=01;35:mu=00;36:lo=00;36:co=01;31:tm=00;90:do=01;34:*.py=01;32:*.js=01;32:*.ts=01;32:*.tsx=01;32:*.jsx=01;32:*.rs=01;32:*.go=01;32:*.rb=01;32:*.java=01;32:*.kt=01;32:*.scala=01;32:*.swift=01;32:*.c=01;32:*.cpp=01;32:*.h=01;32:*.lua=01;32:*.sh=01;32:*.zsh=01;32:*.fish=01;32:*.pl=01;32:*.hs=01;32:*.html=01;34:*.css=01;34:*.scss=01;34:*.sass=01;34:*.less=01;34:*.vue=01;34:*.svelte=01;34:*.astro=01;34:*.json=00;36:*.yaml=00;36:*.yml=00;36:*.toml=00;36:*.xml=00;36:*.ini=00;36:*.conf=00;36:*.env=00;90:*.gitignore=00;90:Makefile=01;33:Dockerfile=01;33:*.mk=01;33:Cargo.toml=01;33:package.json=01;33:go.mod=01;33"

# bat renders with ANSI escapes so colors survive paging and preview panes.
set -gx BAT_THEME ansi
