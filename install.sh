#!/bin/sh -eu

\cp .vimrc ~/.vimrc
\cp .gvimrc ~/.gvimrc

[ ! -d ~/.vim/ ] && \mkdir ~/.vim/ || :
\cp -R autoload/ ~/.vim/
