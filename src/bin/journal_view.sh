#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Journal entry viewing functionality
# ===========================================

# Constants
EXIT_SUCCESS=0
EXIT_FAILURE=1

# ===========================================
# Configuration variables
# ===========================================
JOURNAL_DIR="$HOME/.coding_journal"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
CONFIG_DIR="$JOURNAL_DIR/config"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"

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

# Source settings
source_file "$SETTINGS_FILE" "Settings file not found. Please run setup script first."

# Source utility functions
source_file "$UTILS_SCRIPT" "Utility script not found at $UTILS_SCRIPT" "false"
if [[ $? -ne 0 ]]; then
  # Fallback implementations for critical functions
  function format_month() { echo "$1"; }
  function print_line() { local width=${1:-80}; printf "%0.s-" $(seq 1 $width); echo ""; }
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

# ===========================================
# View Functions
# ===========================================

# List all available journal entries by month
# Usage: list_journals
# Returns: 0 on success, 1 if no entries found
function list_journals() {
  log_info "Listing all available journal entries"
  
  echo " 📚 Available Journal Months: "
  print_line
  echo ""
  
  # Ensure data directory exists
  if [[ ! -d "$DATA_DIR" ]]; then
    log_warning "Data directory not found: $DATA_DIR"
    echo "No journal entries found."
    return $EXIT_FAILURE
  fi
  
  # Find all markdown files in the data directory and sort by date (most recent first)
  local files=($(ls -1 "$DATA_DIR"/*.md 2>/dev/null | sort -r))
  
  # Check if any journal files exist
  if [[ ${#files[@]} -eq 0 ]]; then
    log_warning "No journal files found in $DATA_DIR"
    echo "No journal entries found."
    return $EXIT_FAILURE
  fi
  
  log_debug "Found ${#files[@]} journal files"
  
  # Process each file to display summary
  for file in "${files[@]}"; do
    # Extract month from filename
    local month=$(basename "$file" .md)
    
    # Verify file is readable
    if [[ ! -r "$file" ]]; then
      log_warning "Cannot read file: $file. Skipping."
      continue
    fi
    
    # Count entries in the file
    local entry_count=0
    if command -v grep &> /dev/null; then
      entry_count=$(grep -c "^## Coding Session" "$file" 2>/dev/null || echo 0)
    else
      # Fallback if grep is not available
      while IFS= read -r line; do
        if [[ "$line" =~ ^"## Coding Session" ]]; then
          ((entry_count++))
        fi
      done < "$file"
    fi
    
    # Format month for display
    local display_month=$(format_month "$month")
    echo "📔 $display_month: $entry_count entries"
  done
  
  echo ""
  echo "Use 'journash view DD-MM-YYYY' to view a specific date."
  echo "Use 'journash view MM-YYYY' to view all entries for a month."
  
  return $EXIT_SUCCESS
}

# View entries for a specific day
# Usage: view_day <date>
# Parameters:
#   date - Date in DD-MM-YYYY format
# Returns: 0 on success, 1 if no entries found
function view_day() {
  local date_str="$1"
  local file_path="$DATA_DIR/$date_str.md"
  
  # Verify file exists
  if [[ ! -f "$file_path" ]]; then
    log_warning "Journal file not found: $file_path"
    echo "❌ No entries found for $date_str"
    list_journals
    return $EXIT_FAILURE
  fi
  
  # Verify file is readable
  if [[ ! -r "$file_path" ]]; then
    log_error "Cannot read journal file: $file_path"
    echo "❌ Cannot read journal file for $date_str"
    return $EXIT_FAILURE
  fi
  
  # Format date for display
  local display_date=$(format_month "$date_str")
  
  echo "📖 Viewing entries for $display_date"
  print_line
  echo ""
  
  # Display file content
  if command -v less &> /dev/null; then
    log_debug "Using less to display file"
    less -R "$file_path"
  else
    log_debug "Using cat to display file"
    cat "$file_path"
  fi
  
  return $EXIT_SUCCESS
}

# View entries for an entire month
# Usage: view_month_entries <month> <year>
# Parameters:
#   month - Month (MM format)
#   year - Year (YYYY format)
# Returns: 0 on success, 1 if no entries found
function view_month_entries() {
  local month="$1"
  local year="$2"
  
  # Find all files matching DD-MM-YYYY pattern for this month
  local matching_files=($(ls -1 "$DATA_DIR"/[0-9][0-9]-$month-$year.md 2>/dev/null))
  
  if [[ ${#matching_files[@]} -eq 0 ]]; then
    log_warning "No entries found for month: $month-$year"
    echo "❌ No entries found for $month-$year"
    list_journals
    return $EXIT_FAILURE
  fi
  
  log_debug "Found ${#matching_files[@]} entries for $month-$year"
  
  # Display all matching entries
  echo "📖 Viewing all entries for $month-$year"
  print_line
  echo ""
  
  # Display all files
  if command -v less &> /dev/null; then
    log_debug "Using less to display multiple files"
    cat "${matching_files[@]}" | less -R
  else
    log_debug "Using cat to display multiple files"
    cat "${matching_files[@]}"
  fi
  
  return $EXIT_SUCCESS
}

# Process view command with arguments
# Usage: process_view_command [args...]
# Parameters:
#   args - Optional date to view (DD-MM-YYYY or MM-YYYY format)
# Returns: Exit code from called function
function process_view_command() {
  if [[ $# -eq 0 ]]; then
    # List all journals
    log_debug "No date specified, listing all journals"
    list_journals
    return $?
  fi

  local date_arg="$1"
  
  # Check if input is DD-MM-YYYY format (specific day)
  if [[ "$date_arg" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
    log_debug "Viewing specific day: $date_arg"
    view_day "$date_arg"
    return $?
  fi
  
  # Check if input is MM-YYYY format (entire month)
  if [[ "$date_arg" =~ ^[0-9]{2}-[0-9]{4}$ ]]; then
    local month=${date_arg:0:2}
    local year=${date_arg:3:4}
    log_debug "Viewing entire month: $month-$year"
    view_month_entries "$month" "$year"
    return $?
  fi
  
  # Check if input is YYYY-MM format (backward compatibility)
  if [[ "$date_arg" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    local year=${date_arg:0:4}
    local month=${date_arg:5:2}
    echo "⚠️ Note: The YYYY-MM format is deprecated. Please use MM-YYYY format instead."
    log_debug "Converting YYYY-MM to MM-YYYY: $month-$year"
    view_month_entries "$month" "$year"
    return $?
  fi
  
  # Invalid format
  log_error "Invalid date format: $date_arg"
  echo "❌ Invalid date format. Please use one of these formats:"
  echo "   - DD-MM-YYYY for specific day (e.g., 01-05-2025)"
  echo "   - MM-YYYY for entire month (e.g., 05-2025)"
  echo ""
  echo "Examples:"
  echo "  journash view 01-05-2025  # View entries from 1st May 2025"
  echo "  journash view 05-2025     # View all entries from May 2025"
  list_journals
  return $EXIT_FAILURE
}

# ===========================================
# Main execution (when run directly)
# ===========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  process_view_command "$@"
  exit $?
fi
