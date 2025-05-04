#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Journal search functionality
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
# Search Functions
# ===========================================

# Search through journal entries for a specified term
# Usage: search_entries <search_term>
# Parameters:
#   search_term - Term to search for in journal entries
# Returns: 0 if search was successful, 1 on error or if no matches found
function search_entries() {
  local search_term="$1"
  local context_lines="${SEARCH_CONTEXT_LINES:-2}"
  
  # Validate search term
  if [[ -z "$search_term" ]]; then
    log_error "Please provide a search term."
    echo "❌ Please provide a search term."
    echo "Usage: journash search <term>"
    return $EXIT_FAILURE
  fi
  
  log_info "Searching for term: '$search_term'"
  echo "🔍 Searching for: '$search_term'"
  echo ""
  
  # Ensure data directory exists
  if [[ ! -d "$DATA_DIR" ]]; then
    log_warning "Data directory not found: $DATA_DIR"
    echo "No journal entries found to search."
    return $EXIT_FAILURE
  fi
  
  # Find all markdown files in the data directory
  local files=($(ls -1 "$DATA_DIR"/*.md 2>/dev/null))
  
  # Check if any journal files exist
  if [[ ${#files[@]} -eq 0 ]]; then
    log_warning "No journal files found in $DATA_DIR"
    echo "No journal entries found to search."
    return $EXIT_FAILURE
  fi
  
  log_debug "Found ${#files[@]} journal files to search"
  local results_found=false
  
  # Process each journal file
  for file in "${files[@]}"; do
    # Extract month from filename
    local month=$(basename "$file" .md)
    local display_month=$(format_month "$month")
    
    log_debug "Searching file: $file ($display_month)"
    
    # Read the file once into an array (Zsh compatible way)
    # Handle potential errors with file reading
    if [[ ! -r "$file" ]]; then
      log_warning "Cannot read file: $file. Skipping."
      continue
    fi
    
    local file_content=""
    file_content=$(<"$file")
    if [[ $? -ne 0 ]]; then
      log_warning "Failed to read file content: $file. Skipping."
      continue
    fi
    
    local file_lines=("${(f)file_content}")
    local line_count=${#file_lines[@]}
    local found_match=false
    
    log_debug "Processing $line_count lines in $file"
    
    # Process the file and look for matches
    for ((i=1; i<=line_count; i++)); do
      local line="${file_lines[i]}"
      
      # Case-insensitive search (Zsh way)
      if [[ "${line:l}" == *"${search_term:l}"* ]]; then
        # If this is the first match in this file, print the header
        if [[ "$found_match" == "false" ]]; then
          echo "📔 Results from $display_month:"
          echo "----------------------------"
          found_match=true
          results_found=true
        fi
        
        # Print matching line with context
        echo "  Line $i: $line"
        
        # Print context lines before
        for ((j=i-context_lines; j<i; j++)); do
          if [[ $j -ge 1 ]]; then
            echo "    Context: ${file_lines[j]}"
          fi
        done
        
        # Print context lines after
        for ((j=i+1; j<=i+context_lines && j<=line_count; j++)); do
          echo "    Context: ${file_lines[j]}"
        done
        
        echo "..." # Separator between matches
      fi
    done
    
    # Add a blank line after results from this file
    if [[ "$found_match" == "true" ]]; then
      echo ""
    fi
  done
  
  # Report if no matches were found
  if [[ "$results_found" == "false" ]]; then
    log_info "No matches found for search term: '$search_term'"
    echo "No matches found for '$search_term'."
    return $EXIT_FAILURE
  fi
  
  return $EXIT_SUCCESS
}

# ===========================================
# Main execution (when run directly)
# ===========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -eq 0 ]]; then
    echo "❌ Please provide a search term."
    echo "Usage: $0 <search_term>"
    exit $EXIT_FAILURE
  fi
  
  search_entries "$1"
  exit $?
fi
