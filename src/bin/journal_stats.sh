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

# =====================================
# Function to display entry statistics
# =====================================
function show_stats() {
  echo "📊 Journal Statistics"
  echo "-------------------"
  
  # Find all markdown files in the data directory
  local files=($(ls -1 "$DATA_DIR"/*.md 2>/dev/null))
  
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No journal entries found."
    return 1
  fi
  
  local total_entries=0
  
  for file in "${files[@]}"; do
    # Count entries in each file
    local file_entries=$(grep -c "^## Coding Session" "$file")
    total_entries=$((total_entries + file_entries))
  done
  
  echo "Total coding journal entries: $total_entries"
  
  # Find the most active month
  local most_active_month=""
  local most_active_count=0
  
  for file in "${files[@]}"; do
    local month=$(basename "$file" .md)
    local count=$(grep -c "^## Coding Session" "$file")
    
    if [[ $count -gt $most_active_count ]]; then
      most_active_month=$month
      most_active_count=$count
    fi
  done
  
  if [[ -n "$most_active_month" ]]; then
    local display_month=$(format_month "$most_active_month")
    echo "Most active month: $display_month ($most_active_count entries)"
  fi
  
  # Display git status
  if [[ "$GIT_ENABLED" == "true" ]]; then
    echo "Git integration is enabled"
    if [[ -n "$GIT_REMOTE_URL" ]]; then
      echo "Remote repository: $GIT_REMOTE_URL"
    else
      echo "No remote repository configured"
    fi
  else
    echo "Git integration is not enabled"
  fi
  
  echo ""
}
