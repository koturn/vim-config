#!/bin/sh -eu

BASEURL='https://raw.githubusercontent.com'

[ ! -d colors/ ] && mkdir colors || :

# $1: User name
# $2: Repository name
# $3: file name
function install_colorscheme() {
  curl "$BASEURL/$1/$2/master/colors/$3" -o "colors/$3"
}

install_colorscheme w0ng vim-hybrid hybrid.vim
install_colorscheme sickill vim-monokai monokai.vim
install_colorscheme momasr molokai molokai.vim
install_colorscheme jonathanfilip vim-lucius lucius.vim
install_colorscheme vim-scripts Wombat wombat.vim
