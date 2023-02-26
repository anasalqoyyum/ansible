# Install Neovim

1. neovim version manager `cargo install --git https://github.com/MordechaiHadad/bob.git`

2. Run `bob install 0.8.1`

3. Run `bob use 0.8.1`

4. Add to `~/.zshrc` `export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"`

5. Install nvchad `git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim` (make sure to delete `~/.local/share/nvim`)
