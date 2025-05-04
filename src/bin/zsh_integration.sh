#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Zsh integration script
# ===========================================

# Constants
EXIT_SUCCESS=0
EXIT_FAILURE=1

# ===========================================
# Configuration variables
# ===========================================
ZSHRC_FILE="$HOME/.zshrc"
JOURNAL_DIR="$HOME/.coding_journal"
JOURNAL_SCRIPT="$JOURNAL_DIR/bin/journal_main.sh"

# ===========================================
# Helper Functions
# ===========================================

# Display error message and exit
# Usage: handle_error <message> [exit_code]
# Parameters:
#   message - Error message to display
#   exit_code - Optional exit code, defaults to 1
# Returns: Never returns (exits script)
function handle_error() {
  local message="$1"
  local exit_code="${2:-$EXIT_FAILURE}"
  
  echo "❌ ERROR: $message" >&2
  exit "$exit_code"
}

# Display warning message
# Usage: show_warning <message>
# Parameters:
#   message - Warning message to display
function show_warning() {
  local message="$1"
  echo "⚠️ WARNING: $message"
}

# Display success message
# Usage: show_success <message>
# Parameters:
#   message - Success message to display
function show_success() {
  local message="$1"
  echo "✅ $message"
}

# Safely execute commands with error handling
# Usage: safe_execute <command> <error_message> [exit_on_error]
# Parameters:
#   command - The command to execute
#   error_message - Message to display if command fails
#   exit_on_error - If "true", exit on error; otherwise just warn (default: "true")
# Returns: 0 on success, exits or returns 1 on failure
function safe_execute() {
  local command="$1"
  local error_message="$2"
  local exit_on_error="${3:-true}"
  
  eval "$command"
  if [[ $? -ne 0 ]]; then
    if [[ "$exit_on_error" == "true" ]]; then
      handle_error "$error_message"
    else
      show_warning "$error_message"
      return $EXIT_FAILURE
    fi
  fi
  
  return $EXIT_SUCCESS
}

# ===========================================
# Main Functions
# ===========================================

# Check prerequisites for zsh integration
# Usage: check_prerequisites
# Returns: 0 on success, exits on failure
function check_prerequisites() {
  echo "Checking prerequisites for Journash zsh integration..."
  
  # Check if zshrc exists
  if [[ ! -f "$ZSHRC_FILE" ]]; then
    handle_error "zsh configuration file not found at $ZSHRC_FILE."
  fi
  
  # Check if journal script exists
  if [[ ! -f "$JOURNAL_SCRIPT" ]]; then
    handle_error "Journal script not found at $JOURNAL_SCRIPT. Please run setup script first."
  fi
  
  # Check if integration already exists
  if grep -q "# Journash Integration" "$ZSHRC_FILE"; then
    echo "Journash integration already exists in $ZSHRC_FILE"
    echo "No changes made."
    exit $EXIT_SUCCESS
  fi
  
  return $EXIT_SUCCESS
}

# Install zsh integration
# Usage: install_zsh_integration
# Returns: 0 on success, exits on failure
function install_zsh_integration() {
  echo "Adding Journash integration to $ZSHRC_FILE"
  
  cat >> "$ZSHRC_FILE" << EOF

# Journash Integration
# Function to allow 'journash' command (unique name to avoid conflicts)
function journash() {
  $JOURNAL_SCRIPT "\$@"
}
  
# ===========================================
# Display Functions
# ===========================================

# Display a formatted session completion message
# Usage: display_session_completed
# Returns: 0 on success
function display_session_completed() {
  clear
  echo -e "\033[1;36m=============================\033[0m"
  echo -e "\033[1;32m ✨ Coding session completed \033[0m"
  echo -e "\033[1;36m=============================\033[0m"
  echo ""
  return 0
}

# Handle journal entry creation after IDE closes
# Usage: post_ide_journal
# Returns: Exit code from journash command
function post_ide_journal() {
  display_session_completed
  journash --post-ide
  return \$?
}

# Clean up temporary files securely
# Usage: cleanup_temp_files <temp_file_path>
# Parameters:
#   temp_file_path - Path to the temporary file to remove
# Returns: 0 if successful, 1 if file doesn't exist or can't be removed
function cleanup_temp_files() {
  local temp_file_path="\$1"
  
  if [[ -z "\$temp_file_path" ]]; then
    return 0
  fi
  
  if [[ -f "\$temp_file_path" ]]; then
    rm -f "\$temp_file_path"
    if [[ \$? -ne 0 ]]; then
      echo "⚠️ WARNING: Failed to remove temporary file: \$temp_file_path"
      return 1
    fi
  fi
  
  return 0
}

# ===========================================
# Main Functions
# ===========================================

# Launch IDE with automatic journaling on close
# Usage: code_journal [path_to_project]
# Parameters:
#   Optional parameters are passed to the IDE command
# Returns: Always returns 0 (background process)
function code_journal() {
  # Load configuration and utilities
  JOURNAL_DIR="$JOURNAL_DIR"
  
  # Source utility script for OS detection if available
  if [[ -f "\$JOURNAL_DIR/bin/journal_utils.sh" ]]; then
    source "\$JOURNAL_DIR/bin/journal_utils.sh"
  else
    function detect_os() { 
      if [[ "\$(uname)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi 
    }
  fi
  
  # Source settings for IDE preferences
  if [[ -f "\$JOURNAL_DIR/config/settings.conf" ]]; then
    source "\$JOURNAL_DIR/config/settings.conf"
  else
    # Default settings if not found
    IDE_COMMAND="cursor"
    IDE_ARGS="--wait"
    TERMINAL_EMULATOR="iterm"
  fi
  
  # Run the IDE opening and journal process in the background
  (
    local temp_script_path=""
    
    # Set trap to call cleanup function on exit, interrupt, or termination
    trap 'cleanup_temp_files "\$temp_script_path"' EXIT INT TERM
    
    # Open the IDE with the configured command
    \$IDE_COMMAND \$IDE_ARGS "\$@"
    
    # After IDE closes, open a terminal for journaling based on OS
    local operating_system=\$(detect_os)
    
    if [[ "\$operating_system" == "macos" ]]; then
      # macOS using AppleScript
      if [[ "\$TERMINAL_EMULATOR" == "iterm" ]]; then
        # Create a temporary script file securely
        temp_script_path=\$(mktemp "\${TMPDIR:-/tmp}/journash_post_ide_XXXXXX.sh")
        
        # Make it executable
        chmod 755 "\$temp_script_path"
        
        # Add content to the script - include actual commands instead of function calls
        cat > "\$temp_script_path" << 'EOFSCRIPT'
#!/bin/zsh
# Display completion message
clear
echo -e "\033[1;36m=============================\033[0m"
echo -e "\033[1;32m ✨ Coding session completed \033[0m"
echo -e "\033[1;36m=============================\033[0m"
echo ""

# Call the journal command with the full path
"__JOURNAL_SCRIPT__" --post-ide
EOFSCRIPT

        # Only do the replacement if JOURNAL_SCRIPT has a value
        if [[ -n "$JOURNAL_SCRIPT" ]]; then
          sed -i "" "s|__JOURNAL_SCRIPT__|$JOURNAL_SCRIPT|g" "\$temp_script_path"
        fi
        
        # Launch iTerm with the script
        osascript -e "tell application \"iTerm\"
          create window with default profile
          tell current window
            tell current session
              write text \"\$temp_script_path\"
            end tell
          end tell
        end tell"
        
        # Small delay to ensure the script has been loaded
        sleep 1
      elif [[ "\$TERMINAL_EMULATOR" == "terminal" ]]; then
        # Alternative for Terminal.app
        osascript -e "tell application \"Terminal\" to do script \"post_ide_journal\""
      else
        # Fallback to command line
        post_ide_journal
      fi
    else
      # Linux using various terminal emulators
      if [[ "\$TERMINAL_EMULATOR" == "gnome-terminal" ]]; then
        gnome-terminal -- bash -c "post_ide_journal; exec bash"
      elif [[ "\$TERMINAL_EMULATOR" == "konsole" ]]; then
        konsole --noclose -e bash -c "post_ide_journal"
      elif [[ "\$TERMINAL_EMULATOR" == "xterm" ]]; then
        xterm -e "post_ide_journal; bash"
      else
        # Fallback to command line
        post_ide_journal
      fi
    fi
  ) &
  
  # Disown the process so it continues running even if terminal is closed
  disown
  
  echo "IDE launched in background. Journal entry will be prompted when IDE closes."
  return 0
}

# End Journash Integration

EOF

  if [[ $? -ne 0 ]]; then
    handle_error "Failed to update $ZSHRC_FILE with Journash integration."
  fi
  
  show_success "Zsh integration complete!"
  echo "Please restart your terminal or run 'source $ZSHRC_FILE' to apply changes."
  echo "You can now use 'journash' to create journal entries."
  echo "Use 'code_journal' instead of your normal IDE command to enable auto-journaling when the IDE closes."
  
  return $EXIT_SUCCESS
}

# ===========================================
# Main Execution
# ===========================================
echo "🔄 Setting up Journash - Coding Journal CLI..."

# Check prerequisites
check_prerequisites

# Install zsh integration
install_zsh_integration

exit $EXIT_SUCCESS
