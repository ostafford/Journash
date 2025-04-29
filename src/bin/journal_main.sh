#!/bin/zsh

# Journash - Coding Journal CLI
# Main script file that provides core functionality

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"

# Source settings if they exist
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# Function to collect multi-line input
function read_multiline() {
  local prompt=$1
  
  echo "$prompt (Press Ctrl+D on a new line when finished)"
  # Using process substitution to capture output directly
  input=$(cat)
  echo "$input"
}

# Function to create a journal entry
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
    # Coding journal prompts
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
    # Personal journal prompts
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

# Function to display entries
function view_entries() {
  local month=$1
  local entries_file=""
  
  if [[ -n "$month" ]]; then
    # View specific month
    entries_file="$DATA_DIR/$month.md"
    if [[ ! -f "$entries_file" ]]; then
      echo "No entries found for $month"
      return 1
    fi
  else
    # View current month by default
    entries_file="$DATA_DIR/$(date +"$JOURNAL_FILE_FORMAT")"
    if [[ ! -f "$entries_file" ]]; then
      echo "No entries found for the current month"
      return 1
    fi
  fi
  
  # Display the entries using 'less' for paging
  less "$entries_file"
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
  # View entries
  if [[ -n "$2" ]]; then
    view_entries "$2"
  else
    view_entries ""
  fi
elif [[ "$1" == "--post-ide" ]]; then
  # Called after IDE closes (same as coding)
  create_journal_entry "coding"
elif [[ "$1" == "help" || "$1" == "--help" ]]; then
  # Display help information
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