#!/bin/zsh

# Journash - Coding Journal CLI
# Main script file that provides core functionality

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"

# ================================
# Source settings if they exist
# ================================
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# =====================================
# Function to collect multi-line input
# =====================================
function read_multiline() {
  local prompt=$1
  
  echo "$prompt (Press Ctrl+D on a new line when finished)"
  # Using process substitution to capture output directly
  input=$(cat)
  echo "$input"
}

# ===================================
# Function to create a journal entry
# ===================================
function create_journal_entry() {
  local entry_type=$1  # "coding" or "personal"
  local date_str=$(date +"%Y-%m-%d %H:%M")
  local file_name=$(date +"$JOURNAL_FILE_FORMAT")
  local file_path="$DATA_DIR/$file_name"
  
  # Create header based on entry type
  if [[ "$entry_type" == "coding" ]]; then
    echo "$PROMPT_SYMBOL Coding Journal - $date_str"
    echo "Creating a new coding journal entry..."
  else
    echo "$PROMPT_SYMBOL Personal Journal - $date_str"
    echo "Creating a new personal journal entry..."
  fi
  
  # Collect journal content
  local entry_content=""
  
  if [[ "$entry_type" == "coding" ]]; then
    # =======================
    # Coding journal prompts
    # =======================
    echo "How long was your coding session? (e.g. 2h 30m)"
    read session_duration
    
    echo "What did you work on today? (Press Ctrl+D on a new line when finished)"
    work_description=$(cat)
    
    echo "What challenges did you face? (Press Ctrl+D on a new line when finished)"
    challenges=$(cat)
    
    echo "What solutions did you discover? (Press Ctrl+D on a new line when finished)"
    solutions=$(cat)
    
    echo "What did you learn today? (Press Ctrl+D on a new line when finished)"
    learnings=$(cat)
    
    echo "What are your next steps? (Press Ctrl+D on a new line when finished)"
    next_steps=$(cat)
    
    # Format the entry in Markdown
    entry_content="## Coding Session - $date_str\n\n"
    entry_content+="**Duration**: $session_duration\n\n"
    entry_content+="**Worked on**: \n$work_description\n\n"
    entry_content+="**Challenges**: \n$challenges\n\n"
    entry_content+="**Solutions**: \n$solutions\n\n"
    entry_content+="**Learned**: \n$learnings\n\n"
    entry_content+="**Next Steps**: \n$next_steps\n\n"
    entry_content+="---\n\n"
  else
    # =========================
    # Personal journal prompts
    # =========================
    echo "What are you most grateful for today? (Press Ctrl+D on a new line when finished)"
    gratitude=$(cat)
    
    echo "What did you accomplish today? (Press Ctrl+D on a new line when finished)"
    accomplishments=$(cat)
    
    echo "What's on your mind? (Press Ctrl+D on a new line when finished)"
    thoughts=$(cat)
    
    # Format the entry in Markdown
    entry_content="## Personal Reflection - $date_str\n\n"
    entry_content+="**Grateful for**: \n$gratitude\n\n"
    entry_content+="**Accomplished**: \n$accomplishments\n\n"
    entry_content+="**Thoughts**: \n$thoughts\n\n"
    entry_content+="---\n\n"
  fi
  
  # Save the entry to file
  if [[ ! -f "$file_path" ]]; then
    # Create new file with header if it doesn't exist
    echo "# Journal Entries for $(date +"%B %Y")\n\n" > "$file_path"
  fi
  
  # Append the entry to the file
  echo "$entry_content" >> "$file_path"
  
  echo "✅ Journal entry saved to $file_path"
}

# ============================
# Function to list entries
# ============================
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
    
    # Format month for display (handle both macOS and Linux date commands)
    if [[ $(uname) == "Darwin" ]]; then
      # macOS
      local display_month=$(date -j -f "%Y-%m" "$month" "+%B %Y" 2>/dev/null || echo "$month")
    else
      # Linux
      local display_month=$(date -d "$month-01" "+%B %Y" 2>/dev/null || echo "$month")
    fi
    
    echo "📔 $display_month: $entry_count entries ($coding_count coding, $personal_count personal)"
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
  
  # Format month for display (handle both macOS and Linux date commands)
  if [[ $(uname) == "Darwin" ]]; then
    # macOS
    local display_month=$(date -j -f "%Y-%m" "$month" "+%B %Y" 2>/dev/null || echo "$month")
  else
    # Linux
    local display_month=$(date -d "$month-01" "+%B %Y" 2>/dev/null || echo "$month")
  fi
  
  echo "📖 Viewing entries for $display_month"
  echo ""
  
  # Use less to display the file with formatting
  less -R "$file_path"
}

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
    
    # Format month for display (handle both macOS and Linux date commands)
    if [[ $(uname) == "Darwin" ]]; then
      # macOS
      local display_month=$(date -j -f "%Y-%m" "$month" "+%B %Y" 2>/dev/null || echo "$month")
    else
      # Linux
      local display_month=$(date -d "$month-01" "+%B %Y" 2>/dev/null || echo "$month")
    fi
    
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
          
          # Highlight the search term (use different methods for macOS and Linux)
          if [[ $(uname) == "Darwin" ]]; then
            # macOS (BSD sed)
            highlighted_content=$(echo "$content" | sed -E "s/$search_term/\\\\033[1;33m&\\\\033[0m/gi")
          else
            # Linux (GNU sed)
            highlighted_content=$(echo "$content" | sed "s/$search_term/\x1B[1;33m&\x1B[0m/gi")
          fi
          
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
    # Format month for display (handle both macOS and Linux date commands)
    if [[ $(uname) == "Darwin" ]]; then
      # macOS
      local display_month=$(date -j -f "%Y-%m" "$most_active_month" "+%B %Y" 2>/dev/null || echo "$most_active_month")
    else
      # Linux
      local display_month=$(date -d "$most_active_month-01" "+%B %Y" 2>/dev/null || echo "$most_active_month")
    fi
    
    echo "Most active month: $display_month ($most_active_count entries)"
  fi
  
  echo ""
}



# Process command line arguments
if [[ $# -eq 0 ]]; then
  # No arguments, default to personal journal
  create_journal_entry "personal"
elif [[ "$1" == "code" || "$1" == "coding" ]]; then
  # Create coding journal entry
  create_journal_entry "coding"
elif [[ "$1" == "personal" ]]; then
  # Create personal journal entry
  create_journal_entry "personal"
elif [[ "$1" == "view" ]]; then
  # Viewing functions
  if [[ $# -eq 1 ]]; then
    # List all journals
    list_journals
  elif [[ "$2" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    # View specific month
    view_month "$2"
  elif [[ "$2" == "search" && -n "$3" ]]; then
    # Search for term
    search_entries "$3"
  elif [[ "$2" == "stats" ]]; then
    # Show statistics
    show_stats
  else
    echo "Usage: journash view [OPTION]"
    echo "View and search journal entries."
    echo ""
    echo "Options:"
    echo "  (no option)    List all available journals"
    echo "  YYYY-MM        View entries for specific month"
    echo "  search TERM    Search for a term across all entries"
    echo "  stats          Show journal statistics"
  fi
elif [[ "$1" == "search" && -n "$2" ]]; then
  # Direct search command
  search_entries "$2"
elif [[ "$1" == "stats" ]]; then
  # Direct stats command
  show_stats
elif [[ "$1" == "--post-ide" ]]; then
  # Called after IDE closes (same as coding)
  create_journal_entry "coding"
elif [[ "$1" == "help" || "$1" == "--help" ]]; then

  # =========================
  # Display help information
  # =========================
  echo "Usage: journash [OPTION]"
  echo "A simple CLI journaling system."
  echo ""
  echo "Options:"
  echo "  code, coding   Create a coding journal entry"
  echo "  personal       Create a personal journal entry"
  echo "  view [month]   View entries (optional: specify month as MM-YYYY)"
  echo "  help           Show this help message"
  echo ""
  echo "Examples:"
  echo "  journash code      # Create a coding journal entry"
  echo "  journash personal  # Create a personal journal entry"
  echo "  journash view      # View recent entries"
  echo "  journash view 04-2025  # View entries from April 2025"
  exit 0
else
  # Unknown argument
  echo "Unknown option: $1"
  echo "Try 'journash help' for more information."
  exit 1
fi