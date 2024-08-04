#!/bin/bash
read -p "Do you want to continue? This will nuke all Neovim config (y/n) " answer

case $answer in
    [Yy]* ) 
        echo "Cleaning..."
        rm -rf ~/.config/nvim
        rm -rf ~/.local/share/nvim
        rm -rf ~/.local/state/nvim
        rm -rf ~/.cache/nvim

        echo "Neovim cleaned up..."
        ;;
    [Nn]* ) 
        echo "Operation cancelled."
        ;;
    * ) 
        echo "Please answer yes or no."
        ;;
esac
