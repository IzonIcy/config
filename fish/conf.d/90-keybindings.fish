# Keybindings, loaded last so this preset owns the final binding state.
#
# Vi keybindings, matching zsh-vi-mode in the zsh setup. fish ships these
# natively, so there is no plugin to install. Remove this file to go back to
# the default emacs bindings.
#
# On ctrl-r: atuin owns history search, not fzf. Atuin initializes in
# config.fish, which fish sources after conf.d, so it binds ctrl-r to
# _atuin_search last and wins. fzf still handles ctrl-t for files and alt-c for
# directories, and `fzf-key-bindings` stays available if you want fzf on ctrl-r
# instead: bind \cr fzf-history-widget will override atuin.
#
# fish has no configurable maximum history size. Its history file is capped
# internally, so there is nothing to set here to match the zsh HISTSIZE of
# 100000. Atuin is the history layer and is where search happens.
if status is-interactive
    fish_vi_key_bindings
end