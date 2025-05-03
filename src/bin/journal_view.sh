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
  echo " 📚 Available Journal Months: "
  echo "=============================="
  echo ""
  
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
  echo "Use 'journash view DD-MM-YYYY' to view a specific date."
}

# ==============================================
# Function to view entries for a specific month
# ==============================================
function view_month() {
  local input_date=$1
  local file_path
  
  # Check if input is in DD-MM-YYYY format
  if [[ "$input_date" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
    file_path="$DATA_DIR/$input_date.md"
  # Check if input is in YYYY-MM format (for backward compatibility)
  elif [[ "$input_date" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    # Extract year and month, then find matching files
    local year=${input_date:0:4}
    local month=${input_date:5:2}
    
    # Look for any file matching the pattern DD-MM-YYYY where MM and YYYY match input
    local matching_files=($(ls -1 "$DATA_DIR"/[0-9][0-9]-$month-$year.md 2>/dev/null))
    
    if [[ ${#matching_files[@]} -gt 0 ]]; then
      # Use the first matching file
      file_path="${matching_files[0]}"
    else
      # No matching files found
      echo "❌ No entries found for $input_date"
      list_journals
      return 1
    fi
  else
    echo "❌ Invalid date format. Please use DD-MM-YYYY format."
    list_journals
    return 1
  fi
  
  if [[ ! -f "$file_path" ]]; then
    echo "❌ No entries found for $input_date"
    list_journals
    return 1
  fi
  
  # Format month for display
  local display_month=$(basename "$file_path" .md)
  
  echo "📖 Viewing entries for $display_month"
  echo ""
  
  less -R "$file_path"
}

# In journal_view.sh, make sure this function is defined:
function process_view_command() {
  if [[ $# -eq 0 ]]; then
    # List all journals
    list_journals
  elif [[ "$1" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
    # View specific date in DD-MM-YYYY format
    view_month "$1"
  elif [[ "$1" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    # For backward compatibility with YYYY-MM format
    # Convert to DD-MM-YYYY format by assuming day 01
    local year=${1:0:4}
    local month=${1:5:2}
    view_month "01-${month}-${year}"
  else
    echo "❌ Invalid date format. Please use DD-MM-YYYY format."
    echo "Usage: journash view [DD-MM-YYYY]"
    echo "Example: journash view 01-05-2025  # View entries from 1st May 2025"
    list_journals
  fi
}