#!/bin/zsh

# Journash - Coding Journal CLI
# Git integration for automatic backups

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"
GIT_CONFIG_FILE="$CONFIG_DIR/git.conf"

# Source utility functions if available
if [[ -f "$UTILS_SCRIPT" ]]; then
  source "$UTILS_SCRIPT"
else
  echo "Warning: Utility script not found at $UTILS_SCRIPT"
  # Fallback for critical functions
  function print_line() { echo "----------------------"; }
fi

# Source settings if they exist
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# Source git configuration if it exists
if [[ -f "$GIT_CONFIG_FILE" ]]; then
  source "$GIT_CONFIG_FILE"
fi

# Function to check if git is available
function check_git_available() {
  if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Git integration is not available."
    return 1
  fi
  
  return 0
}

# Function to initialize git repository
function init_repository() {
  # Check if git is installed
  if ! check_git_available; then
    return 1
  fi
  
  # Change to journal directory
  cd "$JOURNAL_DIR" || return 1
  
  # Check if git repo already exists
  if [[ -d ".git" ]]; then
    echo "Git repository already exists in $JOURNAL_DIR"
    return 0
  fi
  
  # Initialize git repository
  echo "Initializing git repository in $JOURNAL_DIR..."
  git init
  
  # Create .gitignore file
  echo "Creating .gitignore file..."
  cat > ".gitignore" << EOF
# Journash .gitignore

# Ignore temporary files
*.bak
*.tmp
*~

# Ignore security-related files (optional)
# Uncomment the following line to exclude security configuration
# config/security.conf
EOF
  
  # Create initial commit
  git add .
  git commit -m "Initial commit - Journash setup"
  
  # Create git configuration file
  echo "Creating git configuration file..."
  cat > "$GIT_CONFIG_FILE" << EOF
# Journash Git Configuration

# Git Settings
GIT_ENABLED=true              # Enable/disable git integration
GIT_AUTO_COMMIT=true          # Automatically commit changes
GIT_REMOTE_URL=""             # Remote repository URL (optional)
EOF
  
  source "$GIT_CONFIG_FILE"
  
  echo "✅ Git repository initialized successfully!"
  echo "You can now use 'journash git' commands to manage your journal backups."
}

# Function to commit changes
function commit_changes() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    echo "Git integration is disabled."
    echo "To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  cd "$JOURNAL_DIR" || return 1
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    echo "Git repository not found. Initializing..."
    init_repository
  fi
  
  # Check for changes
  if [[ -z "$(git status --porcelain)" ]]; then
    echo "No changes to commit."
    return 0
  fi
  
  # Add all changes
  git add .
  
  # Commit with timestamp
  git commit -m "Journal update - $(date +"%Y-%m-%d %H:%M")"
  
  echo "✅ Changes committed successfully!"
  
  # Push to remote if configured
  if [[ -n "$GIT_REMOTE_URL" && "$GIT_AUTO_PUSH" == "true" ]]; then
    git push origin master 2>/dev/null || git push origin main 2>/dev/null
    if [[ $? -eq 0 ]]; then
      echo "✅ Changes pushed to remote repository."
    else
      echo "❌ Failed to push to remote repository."
    fi
  fi
}

# Function to set up remote repository
function setup_remote() {
  local remote_url=$1
  
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    echo "Git integration is disabled."
    echo "To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  cd "$JOURNAL_DIR" || return 1
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    echo "Git repository not found. Initializing..."
    init_repository
  fi
  
  # Check if remote URL is provided
  if [[ -z "$remote_url" ]]; then
    echo "Please provide a remote repository URL."
    echo "Example: journash git remote https://github.com/username/journal.git"
    return 1
  fi
  
  # Set remote URL
  echo "Setting remote repository URL to $remote_url..."
  git remote remove origin 2>/dev/null
  git remote add origin "$remote_url"
  
  # Update git configuration
  sed -i.bak "s|^GIT_REMOTE_URL=.*|GIT_REMOTE_URL=\"$remote_url\"|" "$GIT_CONFIG_FILE"
  
  echo "✅ Remote repository configured successfully!"
  echo "Would you like to enable automatic pushing? (y/n)"
  read enable_push
  
  if [[ "$enable_push" == "y" || "$enable_push" == "Y" ]]; then
    sed -i.bak "s/^# GIT_AUTO_PUSH=.*/GIT_AUTO_PUSH=true/" "$GIT_CONFIG_FILE"
    if ! grep -q "GIT_AUTO_PUSH" "$GIT_CONFIG_FILE"; then
      echo "GIT_AUTO_PUSH=true" >> "$GIT_CONFIG_FILE"
    fi
    echo "✅ Automatic pushing enabled."
  else
    sed -i.bak "s/^# GIT_AUTO_PUSH=.*/GIT_AUTO_PUSH=false/" "$GIT_CONFIG_FILE"
    if ! grep -q "GIT_AUTO_PUSH" "$GIT_CONFIG_FILE"; then
      echo "GIT_AUTO_PUSH=false" >> "$GIT_CONFIG_FILE"
    fi
    echo "Automatic pushing disabled."
  fi
  
  # Try initial push
  echo "Attempting initial push to remote repository..."
  git push -u origin master 2>/dev/null || git push -u origin main 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "✅ Initial push successful!"
  else
    echo "❌ Initial push failed. Please check your remote URL and credentials."
    echo "You can try pushing manually later with 'journash git push'."
  fi
}

# Function to push changes to remote
function push_changes() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    echo "Git integration is disabled."
    echo "To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  cd "$JOURNAL_DIR" || return 1
  
  # Check if remote is configured
  if [[ -z "$GIT_REMOTE_URL" ]]; then
    echo "Remote repository is not configured."
    echo "Please set up a remote repository first with 'journash git remote <url>'."
    return 1
  fi
  
  # Push to remote
  echo "Pushing changes to remote repository..."
  git push origin master 2>/dev/null || git push origin main 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "✅ Changes pushed successfully!"
  else
    echo "❌ Failed to push changes. Please check your remote URL and credentials."
  fi
}

# Function to show git status
function show_status() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    echo "Git integration is disabled."
    echo "To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  cd "$JOURNAL_DIR" || return 1
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    echo "Git repository not found. Initializing..."
    init_repository
  fi
  
  # Show status
  echo "📊 Git Repository Status"
  print_line
  
  echo "Repository location: $JOURNAL_DIR"
  if [[ -n "$GIT_REMOTE_URL" ]]; then
    echo "Remote URL: $GIT_REMOTE_URL"
  else
    echo "Remote URL: Not configured"
  fi
  
  # Show uncommitted changes
  echo ""
  echo "Uncommitted changes:"
  git status --short
  
  # Show recent commits
  echo ""
  echo "Recent commits:"
  git log --oneline -n 5
}

# Process command line arguments
if [[ $# -eq 0 || "$1" == "help" ]]; then
  # Display help information
  echo "Usage: journash git [COMMAND]"
  echo "Manage git integration for journal backups."
  echo ""
  echo "Commands:"
  echo "  init              Initialize git repository"
  echo "  commit            Commit changes"
  echo "  remote <url>      Set up remote repository"
  echo "  push              Push changes to remote"
  echo "  status            Show git status"
  echo "  help              Show this help message"
  echo ""
  echo "Examples:"
  echo "  journash git init                                       # Initialize git repository"
  echo "  journash git remote https://github.com/username/repo.git # Set up remote repository"
  echo "  journash git commit                                     # Commit changes"
elif [[ "$1" == "init" ]]; then
  init_repository
elif [[ "$1" == "commit" ]]; then
  commit_changes
elif [[ "$1" == "remote" && -n "$2" ]]; then
  setup_remote "$2"
elif [[ "$1" == "push" ]]; then
  push_changes
elif [[ "$1" == "status" ]]; then
  show_status
else
  echo "Unknown command: $1"
  echo "Try 'journash git help' for more information."
  exit 1
fi
