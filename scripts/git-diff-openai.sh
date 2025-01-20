# ~/.dotfiles/scripts/git-diff-openai.sh
#!/bin/bash

# Check if running from a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a git repository"
    exit 1
fi

# Load environment variables from ~/.env if it exists
if [ -f ~/.env ]; then
    # Only export OPENAI_API_KEY to avoid loading unnecessary variables
    export $(grep OPENAI_API_KEY ~/.env | xargs)
fi

# Check if API key is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY not found in environment"
    echo "Please add OPENAI_API_KEY to your ~/.env file"
    exit 1
fi

# Function to get AI response
get_ai_response() {
    local diff_content=$1
    local prompt=$2
    
    # Escape the diff content for JSON
    local escaped_diff=$(echo "$diff_content" | jq -sR .)
    
    # Make the API request with error handling
    local response=$(curl -s -w "\n%{http_code}" https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"$prompt\"
                },
                {
                    \"role\": \"user\",
                    \"content\": $escaped_diff
                }
            ]
        }")
    
    # Split response into body and status code
    local http_body=$(echo "$response" | sed '$d')
    local http_status=$(echo "$response" | tail -n1)
    
    # Check for API errors
    if [ "$http_status" -ne 200 ]; then
        echo "Error: API request failed with status $http_status"
        echo "Response: $http_body"
        exit 1
    fi
    
    echo "$http_body" | jq -r '.choices[0].message.content'
}

# Check for unstaged changes
if [ ! -z "$(git diff)" ]; then
    echo "Warning: You have unstaged changes"
    read -p "Would you like to stage all changes? (y/n): " stage_all
    if [[ $stage_all =~ ^[Yy]$ ]]; then
        git add -A
    else
        echo "Please stage your changes and try again"
        exit 1
    fi
fi

# Check if there are any staged changes
if [ -z "$(git diff --staged)" ]; then
    echo "Error: No staged changes found"
    echo "Please stage your changes using 'git add' first"
    exit 1
fi

# Get the staged diff
DIFF_CONTENT=$(git diff --staged)

while true; do
    # Generate commit message
    echo "Analyzing changes and generating commit message..."
    COMMIT_MSG=$(get_ai_response "$DIFF_CONTENT" "You are a commit message generator. Analyze the following git diff and generate a concise, descriptive commit message following conventional commits format. The message should be a single line, under 72 characters.")
    
    echo -e "\nProposed commit message:\n$COMMIT_MSG"
    read -p "Accept this commit message? (y/n): " accept
    
    if [[ $accept =~ ^[Yy]$ ]]; then
        # Commit and push
        if git commit -m "$COMMIT_MSG"; then
            echo "Changes committed successfully"
            echo "Pushing to remote..."
            if git push origin $(git symbolic-ref --short HEAD); then
                echo "Changes pushed successfully"
                exit 0
            else
                echo "Error: Failed to push changes"
                exit 1
            fi
        else
            echo "Error: Failed to commit changes"
            exit 1
        fi
    else
        read -p "Would you like to generate another message? (y/n): " regenerate
        if [[ ! $regenerate =~ ^[Yy]$ ]]; then
            echo "Operation cancelled"
            exit 0
        fi
    fi
done
