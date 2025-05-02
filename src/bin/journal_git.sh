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
  function log_error() { echo "ERROR: $1" >&2; }
  function log_info() { echo "INFO: $1"; }
  function log_warning() { echo "WARNING: $1"; }
  function log_debug() { if [[ "${DEBUG:-false}" == "true" ]]; then echo "DEBUG: $1"; fi; }
  function command_exists() { command -v "$1" &> /dev/null; }
  function safe_exec() { 
    eval "$1"
    if [[ $? -ne 0 ]]; then echo "ERROR: ${2:-Command failed: $1}" >&2; return 1; fi
    return 0
  }
fi

# Source settings if they exist
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  log_error "Settings file not found. Please run setup script first."
  exit 1
fi

# Source git configuration if it exists
if [[ -f "$GIT_CONFIG_FILE" ]]; then
  source "$GIT_CONFIG_FILE"
else
  log_warning "Git configuration file not found. Using default settings."
  GIT_ENABLED="false"
  GIT_AUTO_COMMIT="false"
  GIT_AUTO_PUSH="false"
  GIT_REMOTE_URL=""
fi

# Function to check if git is available
function check_git_available() {
  if ! command_exists "git"; then
    log_error "Git is not installed. Git integration is not available."
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
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return 1
  fi
  
  # Check if git repo already exists
  if [[ -d ".git" ]]; then
    log_info "Git repository already exists in $JOURNAL_DIR"
    return 0
  fi
  
  # Initialize git repository
  log_info "Initializing git repository in $JOURNAL_DIR..."
  if ! safe_exec "git init" "Failed to initialize git repository"; then
    return 1
  fi
  
  # Create .gitignore file
  log_info "Creating .gitignore file..."
  cat > ".gitignore" << EOF
# Journash .gitignore

# Ignore temporary files
*.bak
*.tmp
*~

# Ignore log file
journash.log

# Ignore security-related files (optional)
# Uncomment the following line to exclude security configuration
# config/security.conf
EOF
  
  # Create initial commit
  if ! safe_exec "git add ." "Failed to stage files"; then
    return 1
  fi
  
  if ! safe_exec "git commit -m \"Initial commit - Journash setup\"" "Failed to create initial commit"; then
    return 1
  fi
  
  # Create git configuration file
  log_info "Creating git configuration file..."
  cat > "$GIT_CONFIG_FILE" << EOF
# Journash Git Configuration

# Git Settings
GIT_ENABLED=true              # Enable/disable git integration
GIT_AUTO_COMMIT=true          # Automatically commit changes
GIT_AUTO_PUSH=false           # Automatically push changes
GIT_REMOTE_URL=""             # Remote repository URL (optional)
EOF
  
  source "$GIT_CONFIG_FILE"
  
  log_info "✅ Git repository initialized successfully!"
  log_info "You can now use 'journash git' commands to manage your journal backups."
  
  return 0
}

# Function to commit changes
function commit_changes() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return 1
  fi
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    log_warning "Git repository not found. Initializing..."
    if ! init_repository; then
      return 1
    fi
  fi
  
  # Check for changes
  if [[ -z "$(git status --porcelain)" ]]; then
    log_info "No changes to commit."
    return 0
  fi
  
  # Add all changes
  if ! safe_exec "git add ." "Failed to stage changes"; then
    return 1
  fi
  
  # Commit with timestamp
  if ! safe_exec "git commit -m \"Journal update - $(date +"%Y-%m-%d %H:%M")\"" "Failed to commit changes"; then
    return 1
  fi
  
  log_info "✅ Changes committed successfully!"
  
  # Push to remote if configured
  if [[ -n "$GIT_REMOTE_URL" && "$GIT_AUTO_PUSH" == "true" ]]; then
    push_changes
  fi
  
  return 0
}

# Function to set up remote repository
function setup_remote() {
  local remote_url=$1
  
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return 1
  fi
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    log_warning "Git repository not found. Initializing..."
    if ! init_repository; then
      return 1
    fi
  fi
  
  # Check if remote URL is provided
  if [[ -z "$remote_url" ]]; then
    log_error "Please provide a remote repository URL."
    log_error "Example: journash git remote https://github.com/username/journal.git"
    return 1
  fi
  
  # Set remote URL
  log_info "Setting remote repository URL to $remote_url..."
  git remote remove origin 2>/dev/null
  
  if ! safe_exec "git remote add origin \"$remote_url\"" "Failed to add remote repository"; then
    return 1
  fi
  
  # Update git configuration
  sed -i.bak "s|^GIT_REMOTE_URL=.*|GIT_REMOTE_URL=\"$remote_url\"|" "$GIT_CONFIG_FILE"
  
  log_info "✅ Remote repository configured successfully!"
  echo "Would you like to enable automatic pushing? (y/n)"
  read enable_push
  
  if [[ "$enable_push" == "y" || "$enable_push" == "Y" ]]; then
    # Use pattern replacement to update or add the auto push setting
    if grep -q "^GIT_AUTO_PUSH=" "$GIT_CONFIG_FILE"; then
      sed -i.bak "s/^GIT_AUTO_PUSH=.*/GIT_AUTO_PUSH=true/" "$GIT_CONFIG_FILE"
    else
      echo "GIT_AUTO_PUSH=true" >> "$GIT_CONFIG_FILE"
    fi
    log_info "✅ Automatic pushing enabled."
  else
    if grep -q "^GIT_AUTO_PUSH=" "$GIT_CONFIG_FILE"; then
      sed -i.bak "s/^GIT_AUTO_PUSH=.*/GIT_AUTO_PUSH=false/" "$GIT_CONFIG_FILE"
    else
      echo "GIT_AUTO_PUSH=false" >> "$GIT_CONFIG_FILE"
    fi
    log_info "Automatic pushing disabled."
  fi
  
  # Clean up backup file
  rm -f "$GIT_CONFIG_FILE.bak"
  
  # Try initial push
  log_info "Attempting initial push to remote repository..."
  push_changes
  
  return 0
}

# Function to push changes to remote
function push_changes() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return 1
  fi
  
  # Check if remote is configured
  if [[ -z "$GIT_REMOTE_URL" ]]; then
    log_warning "Remote repository is not configured."
    log_warning "Please set up a remote repository first with 'journash git remote <url>'."
    return 1
  fi
  
  # Try to detect current branch
  local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "master")
  
  # Push to remote
  log_info "Pushing changes to remote repository..."
  if git push origin "$current_branch" 2>/dev/null; then
    log_info "✅ Changes pushed successfully!"
    return 0
  else
    # Try alternate branch name if fails
    if [[ "$current_branch" == "master" ]]; then
      if git push origin main 2>/dev/null; then
        log_info "✅ Changes pushed successfully to 'main' branch!"
        return 0
      fi
    elif [[ "$current_branch" == "main" ]]; then
      if git push origin master 2>/dev/null; then
        log_info "✅ Changes pushed successfully to 'master' branch!"
        return 0
      fi
    fi
    
    log_error "Failed to push changes. Please check your remote URL and credentials."
    return 1
  fi
}

# Function to show git status
function show_status() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return 1
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return 1
  fi
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    log_warning "Git repository not found. Initializing..."
    if ! init_repository; then
      return 1
    fi
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
  
  # Show current branch
  local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "Unknown")
  echo "Current branch: $current_branch"
  
  # Show auto-commit and auto-push status
  echo "Auto-commit: $GIT_AUTO_COMMIT"
  echo "Auto-push: ${GIT_AUTO_PUSH:-false}"
  
  # Show uncommitted changes
  echo ""
  echo "Uncommitted changes:"
  git status --short
  
  # Show recent commits
  echo ""
  echo "Recent commits:"
  git log --oneline -n 5
  
  return 0
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
  log_error "Unknown command: $1"
  log_error "Try 'journash git help' for more information."
  exit 1
fi
