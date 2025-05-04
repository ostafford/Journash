#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Main script file that provides core functionality
# ===========================================

# Constants
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_INVALID_ARGS=2

# ===========================================
# Configuration variables
# ===========================================
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"

SETTINGS_FILE="$CONFIG_DIR/settings.conf"
GIT_CONFIG_FILE="$CONFIG_DIR/git.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"
GIT_SCRIPT="$BIN_DIR/journal_git.sh"

# ===========================================
# Helper functions
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
      handle_error "$error_message"
    else
      show_warning "$error_message"
      return 1
    fi
  fi
}

# ===========================================
# Display help information
# ===========================================
function show_help() {
  echo "Usage: journash [COMMAND]"
  echo "A CLI system for tracking your coding journey."
  echo ""
  echo "Commands:"
  echo "  (no option)         Create a coding journal entry"
  echo "  view                List all available journals"
  echo "  view YYYY-MM        View entries for specific month"
  echo "  search TERM         Search for a term across all entries"
  echo "  stats               Show journal statistics"
  echo "  git                 Manage git repository for backups"
  echo "  test                Test system compatibility"
  echo "  help                Show this help message"
  echo ""
  echo "Examples:"
  echo "  journash                      # Create a coding journal entry"
  echo "  journash view                 # List all available journals"
  echo "  journash view 01-05-2025      # View entries from 1st May 2025"
  echo "  journash search \"python\"    # Search for entries containing 'python'"
  echo "  journash git init             # Initialize git repository for backups"
  exit $EXIT_SUCCESS
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
  function format_month() { echo "$1"; }
  function print_line() { echo "----------------------"; }
  function log_info() { echo "INFO: $1"; }
  function log_warning() { echo "WARNING: $1"; }
  function log_error() { echo "ERROR: $1" >&2; }
fi

# Source main settings
source_file "$SETTINGS_FILE" "Settings file not found. Please run setup script first."

# Source git configuration
source_file "$GIT_CONFIG_FILE" "Git configuration not found. Git features disabled." "false"
if [[ $? -ne 0 ]]; then
  GIT_ENABLED=false
  GIT_AUTO_COMMIT=false
  log_info "Git integration disabled"
fi

# Source component scripts
source_file "$BIN_DIR/journal_entry.sh" "Journal entry component not found"
source_file "$BIN_DIR/journal_view.sh" "Journal view component not found"
source_file "$BIN_DIR/journal_search.sh" "Journal search component not found"
source_file "$BIN_DIR/journal_stats.sh" "Journal stats component not found"

# ===========================================
# Command processing
# ===========================================

# Process and route command line arguments
# Usage: process_commands <arguments...>
# Parameters:
#   arguments - Command line arguments to process
function process_commands() {
  if [[ $# -eq 0 ]]; then
    # No arguments, default to coding journal
    create_coding_journal_entry
    return $?
  fi

  local command="$1"
  case "$command" in
    "code"|"coding")
      # Create coding journal entry
      create_coding_journal_entry
      ;;
    "view")
      # Viewing commands - pass to view component
      shift  # Remove 'view' from arguments
      process_view_command "$@"
      ;;
    "search")
      # Search commands - pass to search component
      if [[ -n "$2" ]]; then
        search_entries "$2"
      else
        log_error "Search term required"
        echo "Usage: journash search TERM"
        return $EXIT_INVALID_ARGS
      fi
      ;;
    "stats")
      # Stats commands - pass to stats component
      show_stats
      ;;
    "git")
      # Git integration commands
      if [[ -f "$GIT_SCRIPT" ]]; then
        # Pass all arguments to the git script
        shift  # Remove the "git" argument
        "$GIT_SCRIPT" "$@"
      else
        handle_error "Git manager not found. Please run setup script first."
      fi
      ;;
    "test")
      # Test system compatibility
      if [[ -f "$UTILS_SCRIPT" ]]; then
        "$UTILS_SCRIPT"
      else
        handle_error "Utility script not found. Cannot run tests."
      fi
      ;;
    "--post-ide")
      # Called after IDE closes - pass to entry component
      create_coding_journal_entry
      ;;
    "help"|"--help")
      # Display help information
      show_help
      ;;
    *)
      # Unknown argument
      log_error "Unknown command: $command"
      echo "Try 'journash help' for more information."
      return $EXIT_INVALID_ARGS
      ;;
  esac
  
  return $EXIT_SUCCESS
}

# ===========================================
# Main execution
# ===========================================
process_commands "$@"
exit $?