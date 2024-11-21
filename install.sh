#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Loop through all dotfiles in the dotfiles directory
find "$DOTFILES_DIR" -type f -name ".*" | while read -r file; do
    # Get just the filename
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

echo "Completed! Backups stored in $BACKUP_DIR"