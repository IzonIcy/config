# History and keybindings.
#
# fish has no configurable maximum history size. Its history file is capped
# internally, so there is nothing to set here to match the zsh HISTSIZE of
# 100000. Atuin is already the history layer in config.fish, which is where
# search actually happens.

# Vi keybindings, matching zsh-vi-mode in the zsh setup. fish ships these
# natively, so there is no plugin to install. Remove this file to go back to
# the default emacs bindings.
if status is-interactive
    fish_vi_key_bindings
end