# Personal Dev Environment Setup

![Preview](https://i.imgur.com/M9Z3nNg.png)

Perhaps can only be applied to WSL Ubuntu (or Unix in General)

For WSL Installation refer to: [WSL Install](https://learn.microsoft.com/en-us/windows/wsl/install)

For Terminal, prefer to use this one: [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/)

## Table of Contents

- [Prerequisites](#prerequisites)
- [Install and set up Zsh and Oh My Zsh](#install-and-set-up-zsh-and-oh-my-zsh)
  - [Zsh](#zsh)
  - [Oh My Zsh](#oh-my-zsh)
- [Install and set up node with nvm](#install-and-set-up-node-with-nvm)
- [Install and set up Golang](#install-and-set-up-golang)
- [Install and set up Python using pyenv](#install-and-set-up-python-using-pyenv)
- [Install and set up Rust](#install-and-set-up-rust)
- [Troubleshoot](#troubleshoot)
  - [Docker vendor_completions issue with zsh](#docker-vendor_completions-issue-with-zsh)

## Prerequisites

1. `sudo apt update && sudo apt upgrade`

2. Install essential package (shamelessly stolen from [anandavj](https://github.com/anandavj/dev-environment))

   ```sh
   sudo apt install \
      build-essential \
      bat \
      curl \
      fzf \
      git \
      libbz2-dev \
      libffi-dev \
      liblzma-dev \
      libncursesw5-dev \
      libreadline-dev \
      libsqlite3-dev \
      libssl-dev \
      libxml2-dev \
      libxmlsec1-dev \
      llvm \
      make \
      tmux \
      tk-dev \
      ripgrep \
      wget \
      xz-utils \
      zlib1g-dev
   ```

3. **[Optional]** [lazygit](https://github.com/jesseduffield/lazygit)

   ```sh
   LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
   curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
   tar xf lazygit.tar.gz lazygit
   sudo install lazygit /usr/local/bin
   ```

   Verify the correct installation of lazygit:

   ```sh
   lazygit --version
   ```

## Install and set up Zsh and Oh My Zsh

### [Zsh](https://www.zsh.org/)

More details can be found here [ohmyzsh/wiki](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)

1. Install Zsh using `sudo apt install zsh`

2. Verify installation by running `zsh --version`

3. Make it your default shell: `chsh -s $(which zsh)`

4. Restart the Terminal and test that it worked with `echo $SHELL`

### [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)

1. Install Oh My Zsh

   ```sh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

2. **[Optional]** Install [Powerlevel10k](https://github.com/romkatv/powerlevel10k)

   - `git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k`

   - Set `ZSH_THEME="powerlevel10k/powerlevel10k"` in ~/.zshrc (or use the dotfiles)

   - Restart Terminal and run `p10k configure` to configure it

3. **[Optional]** Install Zsh Plugin through [Znap!](https://github.com/marlonrichert/zsh-snap)

   ```sh
   git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git
   source zsh-snap/install.zsh
   ```

## Install and set up node with [nvm](https://github.com/nvm-sh/nvm)

1. Run

   ```sh
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
   ```

2. Put this in `~/.zshrc` (if it isn't already there)

   ```sh
   export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
   [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
   ```

3. Run `source ~/.zshrc`

4. Install node `nvm install 16 --lts` (see the available version list using `nvm ls`)

## Install and set up [Golang](https://go.dev/)

1. Download the package through with curl

   ```sh
   curl -OL https://go.dev/dl/go1.20.1.linux-amd64.tar.gz
   ```

2. Do this steps

   ```sh
   sudo tar -C /usr/local -xvf go1.18.10.linux-amd64.tar.gz
   ```

3. Add this to `.zshrc`

   ```sh
   export PATH=$PATH:/usr/local/go/bin
   ```

4. `source ~/.zshrc` and check go version `go version`

## Install and set up Python using [pyenv](https://github.com/pyenv/pyenv)

1. Run

   ```sh
   curl https://pyenv.run | bash
   ```

2. Put this in `~/.zshrc`

   ```sh
   export PYENV_ROOT="$HOME/.pyenv"
   command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
   eval "$(pyenv init -)"
   ```

3. Run `source ~/.zshrc`

4. Install python `pyenv install 3.11` (see the available version list using `pyenv install --list`)

5. Set it to the default using `pyenv global 3.11`

## Install and set up Rust

1. Run `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

2. `source "$HOME/.cargo/env"`

3. Put this in `~/.zshrc`

   ```sh
   export PATH="$HOME/.cargo/bin:$PATH"
   ```

## Troubleshoot

Some issues that I encountered

### Docker vendor_completions issue with zsh

[Source](https://github.com/docker/for-win/issues/8336#issuecomment-718369597)

Make sure docker desktop is currently running

1. `sudo rm -rf /usr/share/zsh/vendor-completions/_docker`

2. `sudo cp /mnt/wsl/docker-desktop/cli-tools/usr/share/zsh/vendor-completions/_docker /usr/share/zsh/vendor-completions/`

3. `sudo chattr +i /usr/share/zsh/vendor-completions/_docker`
