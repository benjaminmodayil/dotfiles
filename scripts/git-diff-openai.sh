# ~/.dotfiles/scripts/git-diff-openai.sh
#!/bin/bash

# Parse arguments
MANUAL_MSG=""
NO_PUSH=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--message)
            MANUAL_MSG="$2"
            shift
            shift
            ;;
        --no-push)
            NO_PUSH=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

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
    echo "Please add OPENAI_API_KEY to your ~/.env file - or maybe you haven't run `./install.sh` yet?"
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
        echo "Error: API request failed with status $http_status" >&2
        echo "Response: $http_body" >&2
        return 1
    fi
    
    echo "$http_body" | jq -r '.choices[0].message.content'
}

# Check for unstaged changes
if [ ! -z "$(git diff)" ]; then
    echo "Warning: You have unstaged changes"
    echo "Here are your current changes:"
    git status --short
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

# Function to process diff content
process_diff_content() {
    local diff_content=$1
    local processed_content=""
    local current_file=""
    local is_deleted=false
    local is_dependency=false
    
    # Files to summarize
    local summarize_patterns=(
        "package-lock.json"
        "yarn.lock"
        "pnpm-lock.yaml"
        "bun.lockb"
        "composer.lock"
        "Gemfile.lock"
        "poetry.lock"
        "Cargo.lock"
        ".min.js"
        ".min.css"
        "dist/"
        "build/"
    )

    while IFS= read -r line; do
        # Check for new file in diff
        if [[ $line =~ ^diff\ --git ]]; then
            # If we were processing a dependency file, add summary before moving to next file
            if [[ $is_dependency == true ]]; then
                processed_content+="[Dependencies updated in $current_file]"$'\n'
            fi
            
            # Reset flags for new file
            is_deleted=false
            is_dependency=false
            current_file=$(echo "$line" | sed -E 's/^diff --git a\/(.*) b\/.*/\1/')
            
            # Check if file should be summarized
            for pattern in "${summarize_patterns[@]}"; do
                if [[ $current_file == *"$pattern"* ]]; then
                    is_dependency=true
                    processed_content+="$line"$'\n'
                    break
                fi
            done
        fi

        # Check if file is being deleted
        if [[ $line =~ ^deleted\ file\ mode ]]; then
            is_deleted=true
            processed_content+="[File deleted: $current_file]"$'\n'
            continue
        fi

        # Add line if it's not a dependency file
        if [[ $is_dependency == false && $is_deleted == false ]]; then
            processed_content+="$line"$'\n'
        fi
    done <<< "$diff_content"

    # Handle last file if it was a dependency
    if [[ $is_dependency == true ]]; then
        processed_content+="[Dependencies updated in $current_file]"$'\n'
    fi

    echo "$processed_content"
}

# Get the staged diff
DIFF_CONTENT=$(git diff --staged)

# Process the diff content
PROCESSED_DIFF=$(process_diff_content "$DIFF_CONTENT")

if [ ! -z "$MANUAL_MSG" ]; then
    # Commit and push manual message
    if git commit -m "$MANUAL_MSG"; then
        echo "Changes committed successfully"
        if [ "$NO_PUSH" = false ]; then
            echo "Pushing to remote..."
            if git push origin $(git symbolic-ref --short HEAD); then
                echo "Changes pushed successfully"
                exit 0
            else
                echo "Error: Failed to push changes"
                exit 1
            fi
        else
            echo "Changes not pushed (--no-push flag used)"
            exit 0
        fi
    else
        echo "Error: Failed to commit changes"
        exit 1
    fi
else
    # Original AI generation flow
    while true; do
        # Generate commit message using processed diff
        echo "Analyzing changes and generating commit message..."
        COMMIT_MSG=$(get_ai_response "$PROCESSED_DIFF" "You are a commit message generator. Analyze the following git diff and generate a concise, descriptive commit message following conventional commits format. The message should be a single line, under 72 characters.")
        
        if [ $? -ne 0 ]; then
            echo -e "\nError: Failed to generate commit message. Please check your OpenAI API key and try again."
            exit 1
        fi
        
        echo -e "\nProposed commit message:\n$COMMIT_MSG"
        read -p "Accept this commit message? (y/n): " accept
        
        if [[ $accept =~ ^[Yy]$ ]]; then
            # Commit and push
            if git commit -m "$COMMIT_MSG"; then
                echo "Changes committed successfully"
                if [ "$NO_PUSH" = false ]; then
                    echo "Pushing to remote..."
                    if git push origin $(git symbolic-ref --short HEAD); then
                        echo "Changes pushed successfully"
                        exit 0
                    else
                        echo "Error: Failed to push changes"
                        exit 1
                    fi
                else
                    echo "Changes not pushed (--no-push flag used)"
                    exit 0
                fi
            else
                echo "Error: Failed to commit changes"
                exit 1
            fi
        else
            read -p "Would you like to generate another message? (y/n): " regenerate
            if [[ ! $regenerate =~ ^[Yy]$ ]]; then
                echo -e "\nOperation cancelled"
                echo "You can use the generated message manually with:"
                echo "git scpai -m \"${COMMIT_MSG//\"/\\\"}\""
                exit 0
            fi
        fi
    done
fi
