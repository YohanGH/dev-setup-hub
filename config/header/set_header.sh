#!/bin/zsh

#Option 1: export USER and MAIL in your shell configuration file

#Add in ~/.zshrc your:

#USER
#MAIL
#Option 2: set user and mail values directly in your vimrc

#let g:userName = 'yourLogin'
#let g:mailName = 'yourLogin@proton.me'

# ./set_header.sh

# Set variables

if [ ! -z "$USER" ]
then
    echo "USER=`/usr/bin/whoami`" >> ~/.zshrc
    echo "export USER" >> ~/.zshrc
fi

if [ ! -z "$GROUP" ]
then
    echo "GROUP=`/usr/bin/id -gn $user`" >> ~/.zshrc
    echo "export GROUP" >> ~/.zshrc
fi

if [ ! -z "$MAIL" ]
then
    echo "MAIL="$USER@proton.me"" >> ~/.zshrc
    echo "export MAIL" >> ~/.zshrc
fi

mkdir -p ~/.vim/plugin

# Add stdheader to vim plugins
cp plugin/stdheader.vim ~/.vim/plugin/

source ~/.zshrc
