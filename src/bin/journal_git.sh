#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Git integration for automatic backups
# ===========================================

# Constants
EXIT_SUCCESS=0
EXIT_FAILURE=1

# ===========================================
# Configuration variables
# ===========================================
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"
GIT_CONFIG_FILE="$CONFIG_DIR/git.conf"

# ===========================================
# Helper functions
# ===========================================

# Source file if it exists, otherwise handle error
# Usage: source_file <file_path> <error_message> [required]
# Parameters:
#   file_path - Path to the file to source
#   error_message - Message to display if file is missing
#   required - If "true", exit on error; otherwise just warn (default: "true")
# Returns: 0 on success, exits or returns 1 on failure
function source_file() {
  local file_path="$1"
  local error_message="$2"
  local required="${3:-true}"
  
  if [[ -f "$file_path" ]]; then
    source "$file_path"
    return 0
  else
    if [[ "$required" == "true" ]]; then
      echo "❌ ERROR: $error_message" >&2
      exit $EXIT_FAILURE
    else
      echo "⚠️ WARNING: $error_message"
      return 1
    fi
  fi
}

# ===========================================
# Initialize required dependencies
# ===========================================

# Source utility functions
source_file "$UTILS_SCRIPT" "Utility script not found at $UTILS_SCRIPT" "false"
if [[ $? -ne 0 ]]; then
  # Fallback for critical functions
  function log_error() { echo "❌ ERROR: $1" >&2; }
  function log_info() { echo "ℹ️ INFO: $1"; }
  function log_warning() { echo "⚠️ WARNING: $1"; }
  function log_debug() { if [[ "${DEBUG:-false}" == "true" ]]; then echo "🔍 DEBUG: $1"; fi; }
  function command_exists() { command -v "$1" &> /dev/null; }
  function print_line() { local width=${1:-80}; printf "%0.s-" $(seq 1 $width); echo ""; }
  function safe_exec() { 
    eval "$1"
    if [[ $? -ne 0 ]]; then echo "❌ ERROR: ${2:-Command failed: $1}" >&2; return 1; fi
    return 0
  }
  function handle_error() {
    local message="$1"
    local exit_code="${2:-$EXIT_FAILURE}"
    log_error "$message"
    exit "$exit_code"
  }
fi

# Source settings
source_file "$SETTINGS_FILE" "Settings file not found. Please run setup script first."

# Source git configuration
source_file "$GIT_CONFIG_FILE" "Git configuration file not found. Using default settings." "false"
if [[ $? -ne 0 ]]; then
  log_warning "Git configuration file not found. Using default settings."
  GIT_ENABLED="false"
  GIT_AUTO_COMMIT="false"
  GIT_AUTO_PUSH="false"
  GIT_REMOTE_URL=""
fi

# ===========================================
# Git Integration Functions
# ===========================================

# Check if git is installed and available
# Usage: check_git_available
# Returns: 0 if git is available, 1 if not
function check_git_available() {
  if ! command_exists "git"; then
    log_error "Git is not installed. Git integration is not available."
    return $EXIT_FAILURE
  fi
  
  return $EXIT_SUCCESS
}

# Initialize git repository for journal
# Usage: init_repository
# Returns: 0 on success, 1 on failure
function init_repository() {
  # Check if git is installed
  if ! check_git_available; then
    return $EXIT_FAILURE
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return $EXIT_FAILURE
  fi
  
  # Check if git repo already exists
  if [[ -d ".git" ]]; then
    log_info "Git repository already exists in $JOURNAL_DIR"
    return $EXIT_SUCCESS
  fi
  
  # Initialize git repository
  log_info "Initializing git repository in $JOURNAL_DIR..."
  if ! safe_exec "git init -b main" "Failed to initialize git repository"; then
    return $EXIT_FAILURE
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
    return $EXIT_FAILURE
  fi
  
  if ! safe_exec "git commit -m \"Initial commit - Journash setup\"" "Failed to create initial commit"; then
    return $EXIT_FAILURE
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
  
  return $EXIT_SUCCESS
}

# Commit changes to git repository
# Usage: commit_changes
# Returns: 0 on success, 1 on failure
function commit_changes() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return $EXIT_FAILURE
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return $EXIT_FAILURE
  fi
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    log_warning "Git repository not found. Initializing..."
    if ! init_repository; then
      return $EXIT_FAILURE
    fi
  fi
  
  # Check for changes
  if [[ -z "$(git status --porcelain)" ]]; then
    log_info "No changes to commit."
    return $EXIT_SUCCESS
  fi
  
  # Add all changes
  if ! safe_exec "git add ." "Failed to stage changes"; then
    return $EXIT_FAILURE
  fi
  
  # Commit with timestamp
  if ! safe_exec "git commit -m \"Journal update - $(date +"%d-%m-%Y %H:%M")\"" "Failed to commit changes"; then
    return $EXIT_FAILURE
  fi
  
  log_info "✅ Changes committed successfully!"
  
  # Push to remote if configured
  if [[ -n "$GIT_REMOTE_URL" && "$GIT_AUTO_PUSH" == "true" ]]; then
    push_changes
  fi
  
  return $EXIT_SUCCESS
}

# Set up remote repository for git
# Usage: setup_remote <remote_url>
# Parameters:
#   remote_url - URL of remote repository
# Returns: 0 on success, 1 on failure
function setup_remote() {
  local remote_url=$1
  
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return $EXIT_FAILURE
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return $EXIT_FAILURE
  fi
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    log_warning "Git repository not found. Initializing..."
    if ! init_repository; then
      return $EXIT_FAILURE
    fi
  fi
  
  # Check if remote URL is provided
  if [[ -z "$remote_url" ]]; then
    log_error "Please provide a remote repository URL."
    log_error "Example: journash git remote https://github.com/username/journal.git"
    return $EXIT_FAILURE
  fi
  
  # Set remote URL
  log_info "Setting remote repository URL to $remote_url..."
  git remote remove origin 2>/dev/null
  
  if ! safe_exec "git remote add origin \"$remote_url\"" "Failed to add remote repository"; then
    return $EXIT_FAILURE
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
  
  return $EXIT_SUCCESS
}

# Push changes to remote repository
# Usage: push_changes
# Returns: 0 on success, 1 on failure
function push_changes() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return $EXIT_FAILURE
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return $EXIT_FAILURE
  fi
  
  # Check if remote is configured
  if [[ -z "$GIT_REMOTE_URL" ]]; then
    log_warning "Remote repository is not configured."
    log_warning "Please set up a remote repository first with 'journash git remote <url>'."
    return $EXIT_FAILURE
  fi
  
  # Try to detect current branch
  local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
  
  # Push to remote
  log_info "Pushing changes to remote repository..."
  if git push origin "$current_branch" 2>/dev/null; then
    log_info "✅ Changes pushed successfully!"
    return $EXIT_SUCCESS
  else
    # Try alternate branch name if fails
    if [[ "$current_branch" == "main" && "$current_branch" != "master" ]]; then
      if git push origin master 2>/dev/null; then
        log_info "✅ Changes pushed successfully to 'master' branch!"
        return $EXIT_SUCCESS
      fi
    elif [[ "$current_branch" == "master" && "$current_branch" != "main" ]]; then
      if git push origin main 2>/dev/null; then
        log_info "✅ Changes pushed successfully to 'main' branch!"
        return $EXIT_SUCCESS
      fi
    fi
    
    log_error "Failed to push changes. Please check your remote URL and credentials."
    return $EXIT_FAILURE
  fi
}

# Show git repository status
# Usage: show_status
# Returns: 0 on success, 1 on failure
function show_status() {
  # Check if git is enabled
  if [[ "$GIT_ENABLED" != "true" ]]; then
    log_warning "Git integration is disabled. To enable, set GIT_ENABLED=true in $GIT_CONFIG_FILE"
    return $EXIT_FAILURE
  fi
  
  # Change to journal directory
  if ! cd "$JOURNAL_DIR"; then
    log_error "Failed to change to journal directory: $JOURNAL_DIR"
    return $EXIT_FAILURE
  fi
  
  # Check if git repo exists
  if [[ ! -d ".git" ]]; then
    log_warning "Git repository not found. Initializing..."
    if ! init_repository; then
      return $EXIT_FAILURE
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
  
  return $EXIT_SUCCESS
}

# Display help information for git commands
# Usage: show_git_help
# Returns: Always returns 0
function show_git_help() {
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
  echo "  journash git init                                         # Initialize git repository"
  echo "  journash git remote https://github.com/username/repo.git  # Set up remote repository"
  echo "  journash git commit                                       # Commit changes"
  
  return $EXIT_SUCCESS
}

# ===========================================
# Command Processing
# ===========================================

# Process git commands
# Usage: process_git_command <command> [arguments...]
# Parameters:
#   command - Git subcommand to process
#   arguments - Additional arguments for the command
# Returns: 0 on success, non-zero on failure
function process_git_command() {
  if [[ $# -eq 0 || "$1" == "help" ]]; then
    show_git_help
    return $EXIT_SUCCESS
  fi
  
  local command="$1"
  case "$command" in
    "init")
      init_repository
      ;;
    "commit")
      commit_changes
      ;;
    "remote")
      if [[ -n "$2" ]]; then
        setup_remote "$2"
      else
        log_error "Remote URL required"
        echo "Usage: journash git remote <url>"
        return $EXIT_FAILURE
      fi
      ;;
    "push")
      push_changes
      ;;
    "status")
      show_status
      ;;
    *)
      log_error "Unknown command: $command"
      log_error "Type 'journash git help' for more information."
      return $EXIT_FAILURE
      ;;
  esac
  
  return $?
}

# ===========================================
# Main execution
# ===========================================
process_git_command "$@"
exit $?