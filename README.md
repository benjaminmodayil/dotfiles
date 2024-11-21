Do this once per machine:

1. `chmod +x install.sh`
2. `./install.sh` // symlinks all dotfiles in this repo to `~`

Do this every time you open a new terminal:
`initialize` // reloads zsh, from `~/.dotfiles/.aliases` file

If you have a custom `.zshrc` file say for work, you can leave in the `~` directory and after you run the install script, it will bring it in with your default `.zshrc`.

This is so you don't bring work specific configs into your main repo that you take everywhere. If you want to keep it for other computers, then add it to this repo.
