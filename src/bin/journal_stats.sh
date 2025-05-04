#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Journal statistics functionality
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
  # Fallback implementations for critical functions
  function detect_os() { 
    if [[ "$(uname)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi 
  }
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

# Source settings
source_file "$SETTINGS_FILE" "Settings file not found. Please run setup script first."

# Source git configuration
source_file "$GIT_CONFIG_FILE" "Git configuration file not found. Using default settings." "false"
if [[ $? -ne 0 ]]; then
  GIT_ENABLED="false"
  GIT_REMOTE_URL=""
fi

# ===========================================
# Statistics Functions
# ===========================================

# Calculate and display journal statistics
# Usage: show_stats
# Returns: 0 on success, 1 if no entries found
function show_stats() {
  log_info "Generating journal statistics"
  
  echo "📊 Journal Statistics"
  print_line
  
  # Ensure data directory exists
  if [[ ! -d "$DATA_DIR" ]]; then
    log_warning "Data directory not found: $DATA_DIR"
    echo "No journal entries found."
    return $EXIT_FAILURE
  fi
  
  # Find all markdown files in the data directory
  local files=($(ls -1 "$DATA_DIR"/*.md 2>/dev/null))
  
  # Check if any journal files exist
  if [[ ${#files[@]} -eq 0 ]]; then
    log_warning "No journal files found in $DATA_DIR"
    echo "No journal entries found."
    return $EXIT_FAILURE
  fi
  
  log_debug "Found ${#files[@]} journal files"
  
  local total_entries=0
  local most_active_month=""
  local most_active_count=0
  local oldest_entry=""
  local newest_entry=""
  local total_months=${#files[@]}
  
  # Process each file to gather statistics
  for file in "${files[@]}"; do
    local month=$(basename "$file" .md)
    local count=0
    
    log_debug "Processing file: $file"
    
    # Verify file is readable
    if [[ ! -r "$file" ]]; then
      log_warning "Cannot read file: $file. Skipping."
      continue
    fi
    
    # Read the file once and count entries
    while IFS= read -r line; do
      if [[ "$line" =~ ^"## Coding Session" ]]; then
        ((count++))
      fi
    done < "$file"
    
    log_debug "Found $count entries in $file"
    
    # Update our statistics
    total_entries=$((total_entries + count))
    
    # Check if this is the most active month
    if [[ $count -gt $most_active_count ]]; then
      most_active_month=$month
      most_active_count=$count
    fi
    
    # Track oldest and newest entries (based on filename)
    if [[ -z "$oldest_entry" || "$month" < "$oldest_entry" ]]; then
      oldest_entry=$month
    fi
    
    if [[ -z "$newest_entry" || "$month" > "$newest_entry" ]]; then
      newest_entry=$month
    fi
  done
  
  # Display basic statistics
  echo "Total coding journal entries: $total_entries"
  echo "Total months with entries: $total_months"
  
  # Display average entries per month if applicable
  if [[ $total_months -gt 0 ]]; then
    local avg_entries=$(( (total_entries + (total_months/2)) / total_months ))
    echo "Average entries per month: $avg_entries"
  fi
  
  # Display most active month if applicable
  if [[ -n "$most_active_month" ]]; then
    local display_month=$(format_month "$most_active_month")
    echo "Most active month: $display_month ($most_active_count entries)"
  fi
  
  # Display date range if applicable
  if [[ -n "$oldest_entry" && -n "$newest_entry" ]]; then
    local oldest_display=$(format_month "$oldest_entry")
    local newest_display=$(format_month "$newest_entry")
    echo "Date range: $oldest_display to $newest_display"
  fi
  
  # Display git status
  echo ""
  echo "📁 Storage Information"
  print_line
  
  if [[ "$GIT_ENABLED" == "true" ]]; then
    echo "Git integration: Enabled"
    if [[ -n "$GIT_REMOTE_URL" ]]; then
      echo "Remote repository: $GIT_REMOTE_URL"
    else
      echo "Remote repository: Not configured"
    fi
    
    # Check for uncommitted changes if git is available
    if command -v git &> /dev/null && [[ -d "$JOURNAL_DIR/.git" ]]; then
      if [[ -n "$(cd "$JOURNAL_DIR" && git status --porcelain)" ]]; then
        echo "Uncommitted changes: Yes"
      else
        echo "Uncommitted changes: No"
      fi
    fi
  else
    echo "Git integration: Not enabled"
  fi
  
  # Show file system storage usage
  if command -v du &> /dev/null; then
    local storage_usage=$(du -sh "$DATA_DIR" 2>/dev/null | awk '{print $1}')
    if [[ -n "$storage_usage" ]]; then
      echo "Storage used: $storage_usage"
    fi
  fi
  
  echo ""
  return $EXIT_SUCCESS
}

# ===========================================
# Main execution (when run directly)
# ===========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  show_stats
  exit $?
fi
