#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create scripts directory if it doesn't exist
mkdir -p "$HOME/.local/bin"

# Make scripts executable
chmod +x "$DOTFILES_DIR/scripts/"*.sh

# Symlink scripts to ~/.local/bin
for script in "$DOTFILES_DIR/scripts/"*.sh; do
    filename=$(basename "$script")
    target="$HOME/.local/bin/$filename"
    
    # Backup existing script if it exists and isn't a symlink
    if [ -f "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$BACKUP_DIR/$filename"
        echo "Backed up existing $filename to $BACKUP_DIR"
    fi
    
    # Create symlink
    ln -sf "$script" "$target"
    echo "Created symlink for $filename"
done

# Loop through all dotfiles in the dotfiles directory
find "$DOTFILES_DIR" -maxdepth 1 -type f -name ".*" | while read -r file; do
    filename=$(basename "$file")
    target="$HOME/$filename"
    
    # Backup existing file if it exists and isn't a symlink
    if [ -f "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$BACKUP_DIR/$filename"
        echo "Backed up existing $filename to $BACKUP_DIR"
    fi
    
    # Create symlink
    ln -sf "$file" "$target"
    echo "Created symlink for $filename"
done

# Create .env from .env.example if it doesn't exist
if [ ! -f "$HOME/.env" ] && [ -f "$DOTFILES_DIR/.env.example" ]; then
    cp "$DOTFILES_DIR/.env.example" "$HOME/.env"
    echo "Created .env file. Please update it with your OpenAI API key"
fi

echo "Installation complete! Backups stored in $BACKUP_DIR"
echo "Don't forget to:"
echo "1. Add your OpenAI API key to ~/.env"
echo "2. Add ~/.local/bin to your PATH if it's not already there"