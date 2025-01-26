# Dotfiles

Personal dotfiles configuration including git aliases, scripts, and more.

Credit: [@mathiasbynens](https://github.com/mathiasbynens/dotfiles) for the initial repo structure credit. I believe I used other references that I can't remember at the moment. I then added my own customizations with a lot of help from GPT/Claude to really make it my own and will continue to maintain this repo + grow it as I think of other things I want to add.

## Initial Setup

1. **Fork this repo so you can keep it updated with any of your customizations!**
2. Download/clone as `~/.dotfiles` directory. `~/` denotes your home directory.
3. Run installation:

   ```bash
   cd ~/.dotfiles
   chmod +x install.sh

   # below command will symlink all files to your home directory so you can keep `~/.dotfiles` directory as your source of truth/working area, albeit the symlinking will update each file.
   ./install.sh
   ```

4. Configure environment:

   ```bash
   # Add OpenAI API key to ~/.env. This is required for the git-diff-openai.sh script to work.
   nano ~/.env

   # Add ~/.local/bin to PATH if not already there
   # Add this to ~/.zshrc:
   export PATH="$HOME/.local/bin:$PATH"

   # Reload shell configuration
   source ~/.zshrc
   ```

## Features

### Git AI Commit Messages

Generate AI-powered commit messages using OpenAI:

```bash
# Stage your changes and generate a review commit messag
git scpai
```

`-m` for manual commit message

### Custom Git Aliases

- `git scpai` - Generate commit message using AI
- `git findlogs` - Find console.log statements in changes
- `git findtodos` - Find TODO comments in changes
- And many more (use `git aliases` to list all)

## Work-specific Configuration

If you have a custom `.zshrc` file for work:

1. Keep it in your home directory (`~`)
2. Run the install.sh script `./install.sh`
3. Your work config will be preserved while maintaining dotfiles defaults

This allows you to keep work-specific configs separate from your personal dotfiles. If you want to keep work configs for other computers, add them to this repo.

## New Computer Setup

1. Install Command Line Tools:

   ```bash
   xcode-select --install
   ```

2. Install Homebrew:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

3. Install packages:
   ```bash
   brew tap homebrew/bundle
   brew bundle --file=Brewfile
   ```

## Maintenance

Every time you open a new terminal:

```bash
initialize # reloads zsh, from ~/.dotfiles/.aliases file
```

## What Gets Installed

- Symlinks all dotfiles from this repo to your home directory
- Creates ~/.local/bin directory for scripts
- Sets up git-diff-openai.sh for AI-powered commit messages
- Preserves existing configs by creating backups
