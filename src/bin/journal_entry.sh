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


# ===================================
# Function to create a journal entry
# ===================================
function create_coding_journal_entry() {
  local date_str=$(date +"%d-%m-%Y %H:%M")
  local file_name=$(date +"$JOURNAL_FILE_FORMAT")
  local file_path="$DATA_DIR/$file_name"
  
  echo "$PROMPT_SYMBOL Coding Journal - $date_str"
  echo "Creating a new coding journal entry..."
  echo ""
  echo -e "\033[48;5;95;38;5;214m|==================================================|\033[0m"
  echo -e "\033[48;5;95;38;5;214m|===| Press Ctrl+D on a new line when finished |===|\033[0m"
  echo -e "\033[48;5;95;38;5;214m|==================================================|\033[0m"
  echo ""
  
  # =======================
  # Coding journal prompts
  # =======================
  echo "How long was your coding session? (e.g. 2h 30m)"
  read session_duration
  
  echo "What did you work on today?"
  work_description=$(cat)
  
  echo "What challenges did you face?"
  challenges=$(cat)
  
  echo "What solutions did you discover?"
  solutions=$(cat)
  
  echo "What did you learn today?"
  learnings=$(cat)
  
  echo "What are your next steps?"
  next_steps=$(cat)
  
  # Format the entry in Markdown
  local entry_content="## Coding Session - $date_str\n\n"
  entry_content+="**Duration**: $session_duration\n\n"
  entry_content+="**Worked on**: \n$work_description\n\n"
  entry_content+="**Challenges**: \n$challenges\n\n"
  entry_content+="**Solutions**: \n$solutions\n\n"
  entry_content+="**Learned**: \n$learnings\n\n"
  entry_content+="**Next Steps**: \n$next_steps\n\n"
  entry_content+="---\n\n"
  
  # Save the entry to file
  if [[ ! -f "$file_path" ]]; then
    # Create new file with header if it doesn't exist
    echo "# Coding Journal Entries for $(date +"%d-%m-%Y")\n\n" > "$file_path"
  fi
  
  # Append the entry to the file
  echo "$entry_content" >> "$file_path"
  
  echo "✅ Journal entry saved to $file_path"

  # Commit changes if git is enabled
  if [[ "$GIT_ENABLED" == "true" && "$GIT_AUTO_COMMIT" == "true" && -f "$GIT_SCRIPT" ]]; then
    echo "Committing changes to git repository..."
    "$GIT_SCRIPT" commit
  fi
}
