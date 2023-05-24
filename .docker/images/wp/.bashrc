#
# =================================================================
# A base bash configuration for alpine based images
# =================================================================
#
#

# Configure to line prefix in the shell
export PS1='$(whoami):${PWD##*/}# '

alias m="make"

alias ls='ls --color=auto'

#
# =================================================================
# Makefile autocompletion
# =================================================================
#
# Autocomplete makefile targets from the root Makefile and .make directory
#
# This will NOT include targets prefixed with "_"
#
# @see https://stackoverflow.com/questions/4188324/bash-completion-of-makefile-target
# -h to grep to hide filenames
# -s to grep to hide error messages
#
complete -W "\`grep -shoE '^[^_][a-zA-Z0-9_.-]+:([^=]|$)' ?akefile .make/*.mk | sed 's/[^a-zA-Z0-9_.-]*$//' | grep -v PHONY\`" make m