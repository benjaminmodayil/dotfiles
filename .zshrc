echo "Loading .zshrc configuration..."

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# AVN Configuration
[[ -s "$HOME/.avn/bin/avn.sh" ]] && source "$HOME/.avn/bin/avn.sh"

# Bun Configuration
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"


# Function to check and show installation instructions
function check_tool() {
    local tool=$1
    local install_command=$2
    
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "⚠️  $tool is not installed"
        echo "To install, run:"
        echo "  $install_command"
        echo ""
    fi
}

# Check if tool exists before prompting configuration
check_tool "brew" 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc; source ~/.zshrc'
check_tool "npm" "brew install node"
check_tool "nvm" "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
check_tool "avn" "npm install -g avn avn-nvm avn-n && avn setup"
check_tool "bun" "curl -fsSL https://bun.sh/install | bash"
check_tool "http" "brew install httpie"


# Source additional configurations; ex: `.zshrc.work`
setopt NULL_GLOB  # Prevents error when no matches are found
if ls "$HOME"/.zshrc.* 1> /dev/null 2>&1; then
    for config in "$HOME"/.zshrc.*; do
        if [ -f "$config" ] && [ "$config" != "$HOME/.zshrc.swp" ]; then
            source "$config"
        fi
    done
fi
unsetopt NULL_GLOB  # Reset to default behavior

# Do not add .gitconfig, or .gitignore! Auto-sourced in ~/ if you run the install.sh script
for file in ~/.dotfiles/.{aliases}; do
    [ -r "$file" ] && source "$file"
done

eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Done loading .zshrc configuration!"
