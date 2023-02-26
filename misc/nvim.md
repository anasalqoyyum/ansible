# Install Neovim

1. Install neovim version manager [bob](https://github.com/MordechaiHadad/bob)

   ```sh
   cargo install --git https://github.com/MordechaiHadad/bob.git
   ```

2. Run `bob install 0.8.1`

3. Run `bob use 0.8.1`

4. Add to `~/.zshrc` `export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"`

   ```sh
   export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
   ```

5. Install [nvchad](https://nvchad.com/) (make sure to delete `~/.local/share/nvim` first)

   ```sh
   git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
   ```
