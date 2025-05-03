#!/bin/zsh

# Journash - Coding Journal CLI
# [Component name] functionality

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"

# Source utility functions
if [[ -f "$UTILS_SCRIPT" ]]; then
  source "$UTILS_SCRIPT"
else
  echo "Warning: Utility script not found at $UTILS_SCRIPT"
  # Fallback implementations
  function detect_os() { 
    if [[ "$(uname)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi 
  }
  # Other fallback functions as needed
fi

# Source settings
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi


# ===========================================
# Function to search through journal entries
# ===========================================
function search_entries() {
  local search_term=$1
  
  if [[ -z "$search_term" ]]; then
    echo "❌ Please provide a search term."
    return 1
  fi
  
  echo "🔍 Searching for: '$search_term'"
  echo ""
  
  # Find all markdown files in the data directory
  local files=($(ls -1 "$DATA_DIR"/*.md 2>/dev/null))
  
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No journal entries found to search."
    return 1
  fi
  
  local results_found=false
  
  for file in "${files[@]}"; do
    # Extract month from filename
    local month=$(basename "$file" .md)
    local display_month=$(format_month "$month")
    
    # Read the file once into an array (Zsh compatible way)
    local file_lines=("${(f)$(< "$file")}")
    local line_count=${#file_lines[@]}
    local found_match=false
    
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
        
        # Print matching line with context (2 lines before and after)
        echo "  Line $i: $line"
        
        # Print context lines before
        for ((j=i-2; j<i; j++)); do
          if [[ $j -ge 1 ]]; then
            echo "    Context: ${file_lines[j]}"
          fi
        done
        
        # Print context lines after
        for ((j=i+1; j<=i+2 && j<=line_count; j++)); do
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
  
  if [[ "$results_found" == "false" ]]; then
    echo "No matches found for '$search_term'."
  fi
}