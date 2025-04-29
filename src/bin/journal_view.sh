#!/bin/zsh

# Journash - Coding Journal CLI
# Journal entry viewing functions

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
DATA_DIR="$JOURNAL_DIR/data"
CONFIG_DIR="$JOURNAL_DIR/config"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"

# Source settings if they exist
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# Function to list all available journal files
function list_journals() {
  echo "📚 Available Journal Months:"
  echo "----------------------------"
  
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
    local entry_count=$(grep -c "^## " "$file")
    
    # Count coding vs personal entries
    local coding_count=$(grep -c "^## Coding Session" "$file")
    local personal_count=$(grep -c "^## Personal Reflection" "$file")
    
    # Format month for display
    local display_month=$(date -j -f "%Y-%m" "$month" "+%B %Y" 2>/dev/null || echo "$month")
    
    echo "📔 $display_month: $entry_count entries ($coding_count coding, $personal_count personal)"
  done
  
  echo ""
  echo "Use 'journash view YYYY-MM' to view a specific month."
}

# Function to view entries for a specific month
function view_month() {
  local month=$1
  local file_path="$DATA_DIR/$month.md"
  
  if [[ ! -f "$file_path" ]]; then
    echo "❌ No entries found for $month"
    list_journals
    return 1
  fi
  
  echo "📖 Viewing entries for $(date -j -f "%Y-%m" "$month" "+%B %Y" 2>/dev/null || echo "$month")"
  echo ""
  
  # Use less to display the file with formatting
  less -R "$file_path"
}

# Function to search through journal entries
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
    local display_month=$(date -j -f "%Y-%m" "$month" "+%B %Y" 2>/dev/null || echo "$month")
    
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
          
          # Highlight the search term
          highlighted_content=$(echo "$content" | sed "s/$search_term/\033[1;33m&\033[0m/gi")
          
          echo "  Line $line_num: $highlighted_content"
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

# Function to display entry statistics
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
  local coding_entries=0
  local personal_entries=0
  
  for file in "${files[@]}"; do
    # Count entries in each file
    local file_entries=$(grep -c "^## " "$file")
    local file_coding=$(grep -c "^## Coding Session" "$file")
    local file_personal=$(grep -c "^## Personal Reflection" "$file")
    
    total_entries=$((total_entries + file_entries))
    coding_entries=$((coding_entries + file_coding))
    personal_entries=$((personal_entries + file_personal))
  done
  
  echo "Total journal entries: $total_entries"
  echo "Coding journal entries: $coding_entries"
  echo "Personal journal entries: $personal_entries"
  
  # Find the most active month
  local most_active_month=""
  local most_active_count=0
  
  for file in "${files[@]}"; do
    local month=$(basename "$file" .md)
    local count=$(grep -c "^## " "$file")
    
    if [[ $count -gt $most_active_count ]]; then
      most_active_month=$month
      most_active_count=$count
    fi
  done
  
  if [[ -n "$most_active_month" ]]; then
    local display_month=$(date -j -f "%Y-%m" "$most_active_month" "+%B %Y" 2>/dev/null || echo "$most_active_month")
    echo "Most active month: $display_month ($most_active_count entries)"
  fi
  
  echo ""
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