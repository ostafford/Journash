#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI Setup Script
# ===========================================

# Constants
EXIT_SUCCESS=0
EXIT_FAILURE=1

# ===========================================
# Error Handling Functions
# ===========================================

# Display error message and exit 
# Usage: handle_error <message> [exit_code]
# Parameters:
#   message - Error message to display
#   exit_code - Optional exit code, defaults to 1
function handle_error() {
  local message="$1"
  local exit_code="${2:-$EXIT_FAILURE}"
  
  echo "❌ ERROR: $message" >&2
  exit "$exit_code"
}

# Display warning message but continue execution
# Usage: show_warning <message>
# Parameters:
#   message - Warning message to display
function show_warning() {
  local message="$1"
  echo "⚠️ WARNING: $message"
}

# Execute command safely with error handling
# Usage: safe_execute <command> <error_message>
# Parameters:
#   command - The command to execute
#   error_message - Message to display if command fails
# Returns: 0 on success, exits script on failure
function safe_execute() {
  local command="$1"
  local error_message="$2"
  
  eval "$command"
  if [[ $? -ne 0 ]]; then
    handle_error "$error_message"
  fi
  return $EXIT_SUCCESS
}

echo "🚀 Setting up Journash - Coding Journal CLI..."

# Define the main directory for the journal
JOURNAL_DIR="$HOME/.coding_journal"

# Create main directory if it doesn't exist
if [[ ! -d "$JOURNAL_DIR" ]]; then
  echo "Creating main directory: $JOURNAL_DIR"
  safe_execute "mkdir -p \"$JOURNAL_DIR\"" "Failed to create journal directory: $JOURNAL_DIR"
else
  echo "Main directory already exists: $JOURNAL_DIR"
fi

# Create subdirectories
for dir in "bin" "data" "config"; do
  if [[ ! -d "$JOURNAL_DIR/$dir" ]]; then
    echo "Creating directory: $JOURNAL_DIR/$dir"
    safe_execute "mkdir -p \"$JOURNAL_DIR/$dir\"" "Failed to create directory: $JOURNAL_DIR/$dir"
  else
    echo "Directory already exists: $JOURNAL_DIR/$dir"
  fi
done

# Create default settings.conf if it doesn't exist
SETTINGS_FILE="$JOURNAL_DIR/config/settings.conf"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "Creating default settings file: $SETTINGS_FILE"
  cat > "$SETTINGS_FILE" << EOF
# Journash Configuration File

# IDE Settings
IDE_COMMAND="cursor"        # Command to open the IDE
IDE_ARGS="--wait"           # Arguments for the IDE command
TERMINAL_EMULATOR="iterm"   # Terminal emulator

# Error Handling Settings
LOG_LEVEL=0                 # 0=INFO, 1=WARNING, 2=ERROR, 3=FATAL
LOG_FILE="$JOURNAL_DIR/journash.log"

# Journal Settings
AUTO_JOURNAL_ENABLED=true           # Enable/disable auto-journaling after IDE closes
JOURNAL_FILE_FORMAT="%d-%m-%Y.md"   # Date format for journal files

# Terminal Settings
TERMINAL_WIDTH=80                   # Default terminal width for formatting

# Appearance
PROMPT_SYMBOL="📝"                  # Symbol to use in journal prompts
EOF
  
  if [[ $? -ne 0 ]]; then
    handle_error "Failed to create settings file: $SETTINGS_FILE"
  fi
  echo "Default settings configured."
else
  echo "Settings file already exists: $SETTINGS_FILE"
fi

# Copy main script files to bin directory
SCRIPT_FILES=(
  "journal_main.sh"
  "journal_utils.sh"
  "journal_git.sh"
  "journal_entry.sh"
  "journal_view.sh" 
  "journal_search.sh"
  "journal_stats.sh"
  "zsh_integration.sh"
)

for script in "${SCRIPT_FILES[@]}"; do
  SRC_SCRIPT="./src/bin/$script"
  DEST_SCRIPT="$JOURNAL_DIR/bin/$script"
  
  if [[ -f "$SRC_SCRIPT" ]]; then
    echo "Copying $script to: $DEST_SCRIPT"
    safe_execute "cp \"$SRC_SCRIPT\" \"$DEST_SCRIPT\"" "Failed to copy script: $SRC_SCRIPT"
    safe_execute "chmod +x \"$DEST_SCRIPT\"" "Failed to make script executable: $DEST_SCRIPT"
  else
    show_warning "Script not found at $SRC_SCRIPT. Please create the script file first."
  fi
done

# Check if Zsh integration already exists
if ! grep -q "# Journash Integration" "$HOME/.zshrc"; then
  echo "Setting up Zsh integration..."
  
  # Call the dedicated zsh integration script instead of embedding it here
  safe_execute "$JOURNAL_DIR/bin/zsh_integration.sh" "Failed to set up Zsh integration"
else
  echo "Journash integration already exists in ~/.zshrc"
fi

# Test system compatibility
echo "Testing system compatibility..."
if [[ -f "$JOURNAL_DIR/bin/journal_utils.sh" ]]; then
  "$JOURNAL_DIR/bin/journal_utils.sh"
  if [[ $? -ne 0 ]]; then
    show_warning "System compatibility check failed. Some features may not work correctly."
  fi
else
  show_warning "Utility script not found. Cannot test system compatibility."
fi

# Check for required utilities
echo "Checking for required utilities..."

# Check for Git (required for version control)
if ! command -v git &> /dev/null; then
  show_warning "Git is not installed. Version control features will not be available."
  echo "Please install Git to use backup and versioning features."
else
  echo "✅ Git is available. Version control features can be used."
fi

# Feature setup questions
echo ""
echo "Would you like to set up Git repository for version control and backups? (y/n)"
read setup_git

if [[ "$setup_git" == "y" || "$setup_git" == "Y" ]]; then
  # Check if Git is available
  if command -v git &> /dev/null; then
    if ! "$JOURNAL_DIR/bin/journal_git.sh" init; then
      show_warning "Failed to initialize Git repository. You can run 'journash git init' later."
    fi
    
    echo "Would you like to set up a remote repository for cloud backup? (y/n)"
    read setup_remote
    
    if [[ "$setup_remote" == "y" || "$setup_remote" == "Y" ]]; then
      echo "Please enter the URL of your remote repository:"
      read remote_url
      
      if [[ -n "$remote_url" ]]; then
        if ! "$JOURNAL_DIR/bin/journal_git.sh" remote "$remote_url"; then
          show_warning "Failed to set up remote repository. You can run 'journash git remote $remote_url' later."
        fi
      fi
    fi
  else
    show_warning "Cannot set up Git repository: Git is not installed."
    echo "Please install Git and run 'journash git init' later."
  fi
fi

echo "✅ Journash setup complete!"
echo "You can now use 'journash' to create coding journal entries."
echo "Type 'journash help' to see all available commands."
echo ""
echo "Quick start:"
echo "  journash                - Create a coding journal entry"
echo "  journash view           - View your journal entries"
echo "  journash git            - Manage git repository for backups"
echo ""
echo "For automatic journaling when closing your IDE:"
echo "  Use 'code_journal' instead of your normal IDE command to launch your IDE"
echo "  For example: code_journal ~/projects/my-project-name"

exit $EXIT_SUCCESS