#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Journal entry creation functionality
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
GIT_SCRIPT="$BIN_DIR/journal_git.sh"

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
  # Fallback implementations for critical functions
  function detect_os() { 
    if [[ "$(uname)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi 
  }
  function log_info() { echo "ℹ️ INFO: $1"; }
  function log_warning() { echo "⚠️ WARNING: $1"; }
  function log_error() { echo "❌ ERROR: $1" >&2; }
  function log_debug() { if [[ "${DEBUG:-false}" == "true" ]]; then echo "🔍 DEBUG: $1"; fi; }
  function handle_error() {
    local message="$1"
    local exit_code="${2:-$EXIT_FAILURE}"
    log_error "$message"
    exit "$exit_code"
  }
fi

# Source settings
source_file "$SETTINGS_FILE" "Settings file not found. Please run setup script first."

# ===========================================
# Journal Entry Functions
# ===========================================

# Create a new coding journal entry with user input
# Usage: create_coding_journal_entry
# Returns: 0 on success, 1 on failure
function create_coding_journal_entry() {
  local date_str=$(date +"%d-%m-%Y %H:%M")
  local file_name=$(date +"${JOURNAL_FILE_FORMAT:-%d-%m-%Y.md}")
  local file_path="$DATA_DIR/$file_name"
  
  log_debug "Creating journal entry at $file_path"
  
  # Display journal entry header
  echo "${PROMPT_SYMBOL:-📝} Coding Journal - $date_str"
  echo "Creating a new coding journal entry..."
  echo ""
  echo -e "\033[48;5;95;38;5;214m|==================================================|\033[0m"
  echo -e "\033[48;5;95;38;5;214m|===| Press Ctrl+D on a new line when finished |===|\033[0m"
  echo -e "\033[48;5;95;38;5;214m|==================================================|\033[0m"
  echo ""
  
  # Collect journal entry information
  # Duration
  echo "How long was your coding session? (e.g. 2h 30m)"
  read session_duration
  
  # Work description
  echo "What did you work on today?"
  work_description=$(cat)
  
  # Challenges
  echo "What challenges did you face?"
  challenges=$(cat)
  
  # Solutions
  echo "What solutions did you discover?"
  solutions=$(cat)
  
  # Learnings
  echo "What did you learn today?"
  learnings=$(cat)
  
  # Next steps
  echo "What are your next steps?"
  next_steps=$(cat)
  
  # Format the entry in Markdown
  local entry_content="## Coding Session - $date_str\n\n"
  entry_content+="**Duration**: $session_duration\n\n"
  entry_content+="**Worked on**: \n$work_description\n\n"
  entry_content+="**Challenges**: \n$challenges\n\n"
  entry_content+="**Solutions**: \n$solutions\n\n"
  entry_content+="**Learned**: \n$learnings\n\n"
  entry_content+="**Next Steps**: \n$next_steps\n\n"
  entry_content+="---\n\n"
  
  # Ensure data directory exists
  if [[ ! -d "$DATA_DIR" ]]; then
    log_info "Creating data directory at $DATA_DIR"
    if ! mkdir -p "$DATA_DIR"; then
      log_error "Failed to create data directory: $DATA_DIR"
      return $EXIT_FAILURE
    fi
  fi
  
  # Save the entry to file with better error handling
  if [[ ! -f "$file_path" ]]; then
    # Create new file with header if it doesn't exist
    log_debug "Creating new journal file with header: $file_path"
    if ! echo "# Coding Journal Entries for $(date +"%d-%m-%Y")\n\n" > "$file_path"; then
      log_error "Failed to create journal file: $file_path"
      return $EXIT_FAILURE
    fi
  fi

  # Append the entry to the file
  log_debug "Appending entry to journal file"
  if ! echo "$entry_content" >> "$file_path"; then
    log_error "Failed to append entry to journal file: $file_path"
    return $EXIT_FAILURE
  fi

  log_info "Journal entry saved to $file_path"
  echo "✅ Journal entry saved to $file_path"

  # Commit changes if git is enabled
  if [[ "$GIT_ENABLED" == "true" && "$GIT_AUTO_COMMIT" == "true" && -f "$GIT_SCRIPT" ]]; then
    log_info "Committing changes to git repository"
    echo "Committing changes to git repository..."
    
    if ! "$GIT_SCRIPT" commit; then
      log_warning "Failed to commit changes to git repository"
    fi
  else
    log_debug "Git auto-commit not enabled or Git script not found"
  fi
  
  return $EXIT_SUCCESS
}

# ===========================================
# Main execution (when run directly)
# ===========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  create_coding_journal_entry
  exit $?
fi
