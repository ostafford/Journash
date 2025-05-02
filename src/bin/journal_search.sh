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
  
    
    # Search for term in the file and get matching lines with context
    local matches=$(grep -n -A 2 -B 2 -i "$search_term" "$file")
    
    if [[ -n "$matches" ]]; then
      echo "📔 Results from $display_month:"
      echo "----------------------------"
      # Format and display matches
      echo "$matches" | while read -r line; do
        if [[ "$line" == "--" ]]; then
          echo "..."
        else
          local line_num=$(echo "$line" | cut -d: -f1)
          local content=$(echo "$line" | cut -d: -f2-)
          
          # Use simplified highlighting approach for better cross-platform compatibility
          echo "  Line $line_num: $content"
        fi
      done
      echo ""
      results_found=true
    fi
  done
  
  if [[ "$results_found" == "false" ]]; then
    echo "No matches found for '$search_term'."
  fi
}
