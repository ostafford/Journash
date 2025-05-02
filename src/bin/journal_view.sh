#!/bin/zsh

# Journash - Coding Journal CLI
# Journal entry viewing functions


# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
CONFIG_DIR="$JOURNAL_DIR/config"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"

UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"

# Source settings if they exist
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# Source utility functions if available
if [[ -f "$UTILS_SCRIPT" ]]; then
  source "$UTILS_SCRIPT"
else
  echo "Warning: Utility script not found at $UTILS_SCRIPT"
  # Fallback for format_month function
  function format_month() { echo "$1"; }
fi

# ============================
# Function to list entries
# ============================
function list_journals() {
  echo "📚 Available Journal Months:"
  print_line
  
  # Find all markdown files in the data directory and sort by date
  local files=($(ls -1 "$DATA_DIR"/*.md 2>/dev/null | sort -r))
  
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No journal entries found."
    return 1
  fi
  
  for file in "${files[@]}"; do
    # Extract month from filename
    local month=$(basename "$file" .md)
    
    # Count entries in the file
    local entry_count=$(grep -c "^## Coding Session" "$file")
    
    # Format month for display
    local display_month=$(format_month "$month")
    echo "📔 $display_month: $entry_count entries"
  done
  
  echo ""
  echo "Use 'journash view YYYY-MM' to view a specific month."
}

# ==============================================
# Function to view entries for a specific month
# ==============================================
function view_month() {
  local month=$1
  local file_path="$DATA_DIR/$month.md"
  
  if [[ ! -f "$file_path" ]]; then
    echo "❌ No entries found for $month"
    list_journals
    return 1
  fi
  
  # Format month for display
  local display_month=$(format_month "$month")
  
  echo "📖 Viewing entries for $display_month"
  echo ""
  
  less -R "$file_path"
}

function process_view_command() {
  if [[ $# -eq 0 ]]; then
    # List all journals
    list_journals
  elif [[ "$1" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    # View specific month
    view_month "$1"
  else
    echo "Usage: journash view [OPTION]"
    # Help text
  fi
}

# Process command line arguments
if [[ $# -eq 0 ]]; then
  # No arguments, list all journals
  list_journals
elif [[ "$1" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
  # View specific month (YYYY-MM format)
  view_month "$1"
elif [[ "$1" == "search" && -n "$2" ]]; then
  # Search for term
  search_entries "$2"
elif [[ "$1" == "stats" ]]; then
  # Show statistics
  show_stats
else
  # Unknown argument
  echo "Usage: journash view [OPTION]"
  echo "View and search journal entries."
  echo ""
  echo "Options:"
  echo "  (no option)    List all available journals"
  echo "  YYYY-MM        View entries for specific month"
  echo "  search TERM    Search for a term across all entries"
  echo "  stats          Show journal statistics"
  exit 1
fi