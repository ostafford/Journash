#!/bin/zsh

# Journash - Coding Journal CLI
# Main script file that provides core functionality

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"

SETTINGS_FILE="$CONFIG_DIR/settings.conf"
GIT_CONFIG_FILE="$CONFIG_DIR/git.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"
GIT_SCRIPT="$BIN_DIR/journal_git.sh"

# Source component scripts
source "$BIN_DIR/journal_entry.sh"
source "$BIN_DIR/journal_view.sh"
source "$BIN_DIR/journal_search.sh"
source "$BIN_DIR/journal_stats.sh"
# etc.

# ======================================
# Source utility functions if available
# ======================================
if [[ -f "$UTILS_SCRIPT" ]]; then
  source "$UTILS_SCRIPT"
else
  echo "Warning: Utility script not found at $UTILS_SCRIPT"
  # Fallback implementations for critical functions
  function detect_os() { 
    if [[ "$(uname)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi 
  }
  function format_month() { echo "$1"; }
  function print_line() { echo "----------------------"; }
  function log_message() { echo "$1"; }
fi

# ================================
# Source settings if they exist
# ================================
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# ======================================
# Source git configuration if it exists
# ======================================
if [[ -f "$GIT_CONFIG_FILE" ]]; then
  source "$GIT_CONFIG_FILE"
else
  GIT_ENABLED=false
  GIT_AUTO_COMMIT=false
fi



# Process command line arguments
if [[ $# -eq 0 || "$1" == "code" || "$1" == "coding" ]]; then
  # Default to coding journal
  create_coding_journal_entry
elif [[ "$1" == "view" ]]; then
  # Viewing functions
  if [[ $# -eq 1 ]]; then
    # List all journals
    list_journals
  elif [[ "$2" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    # View specific month
    view_month "$2"
  else
    echo "Usage: journash view [OPTION]"
    echo "View journal entries."
    echo ""
    echo "Options:"
    echo "  (no option)    List all available journals"
    echo "  YYYY-MM        View entries for specific month"
  fi
elif [[ "$1" == "search" && -n "$2" ]]; then
  # Direct search command
  search_entries "$2"
elif [[ "$1" == "stats" ]]; then
  # Direct stats command
  show_stats
elif [[ "$1" == "git" ]]; then
  # Git integration commands
  if [[ -f "$GIT_SCRIPT" ]]; then
    # Pass all arguments to the git script
    shift  # Remove the "git" argument
    "$GIT_SCRIPT" "$@"
  else
    echo "Git manager not found. Please run setup script first."
    exit 1
  fi
elif [[ "$1" == "test" ]]; then
  # Test system compatibility
  if [[ -f "$UTILS_SCRIPT" ]]; then
    "$UTILS_SCRIPT"
  else
    echo "Utility script not found. Cannot run tests."
    exit 1
  fi
elif [[ "$1" == "--post-ide" ]]; then
  # Called after IDE closes
  create_coding_journal_entry
elif [[ "$1" == "help" || "$1" == "--help" ]]; then
  # =========================
  # Display help information
  # =========================
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
  echo "  journash                   # Create a coding journal entry"
  echo "  journash view              # List all available journals"
  echo "  journash view 2025-04      # View entries from April 2025"
  echo "  journash search \"python\"   # Search for entries containing 'python'"
  echo "  journash git init          # Initialize git repository for backups"
  exit 0
else
  # Unknown argument
  echo "Unknown command: $1"
  echo "Try 'journash help' for more information."
  exit 1
fi
