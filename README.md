Do this once per machine:

1. `chmod +x install.sh`
2. `./install.sh` // symlinks all dotfiles in this repo to `~`

Do this every time you open a new terminal:
`initialize` // reloads zsh, from `~/.dotfiles/.aliases` file

If you have a custom `.zshrc` file say for work, you can leave in the `~` directory and after you run the install script, it will bring it in with your default `.zshrc`.

This is so you don't bring work specific configs into your main repo that you take everywhere. If you want to keep it for other computers, then add it to this repo.

---

new computer:

- download zip of repo from github
- rename folder to `.dotfiles`
- move to `~/`
- run above 1 + 2 step.
- cd ~/
- run `source ~/.zshrc`
- see install commands and run each.
- when you try to run brew install, you will get an error: xcode-select: note: No developer tools were found, requesting install. <- when running brew install initially
- run `xcode-select --install`
- run brew installation command again, and then just below
- run `eval "$(/opt/homebrew/bin/brew shellenv)"`

`brew tap Homebrew/bundle` anywhere
`brew bundle --file=Brewfile` in directory with Brewfile
wait for all to install, possibly prefix with sudo for specific programs.
