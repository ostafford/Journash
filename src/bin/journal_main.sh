#!/bin/zsh

# Journash - Coding Journal CLI
# Main script file that provides core functionality

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"

CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"

SETTINGS_FILE="$CONFIG_DIR/settings.conf"
SECURITY_FILE="$CONFIG_DIR/security.conf"
GIT_CONFIG_FILE="$CONFIG_DIR/git.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"
QUOTE_SCRIPT="$BIN_DIR/quote_manager.sh"
SECURITY_SCRIPT="$BIN_DIR/journal_security.sh"
GIT_SCRIPT="$BIN_DIR/journal_git.sh"

# ======================================
# Source utility functions if available
# ======================================
if [[ -f "$UTILS_SCRIPT" ]]; then
  source "$UTILS_SCRIPT"
else
  echo "Warning: Utility script not found at $UTILS_SCRIPT"
  # Fallback implementations for critical functions
  function detect_os() { 
    if [[ "$(uname)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi 
  }
  function format_month() { echo "$1"; }
  function print_line() { echo "----------------------"; }
fi

# ================================
# Source settings if they exist
# ================================
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# =======================================
# Source security settings if they exist
# =======================================
if [[ -f "$SECURITY_FILE" ]]; then
  source "$SECURITY_FILE"
else
  ENCRYPTION_ENABLED=false
fi

# ======================================
# Source git configuration if it exists
# ======================================
if [[ -f "$GIT_CONFIG_FILE" ]]; then
  source "$GIT_CONFIG_FILE"
else
  GIT_ENABLED=false
  GIT_AUTO_COMMIT=false
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
  
  # Check if encryption is enabled and ask if entry should be private
  local is_encrypted=false
  if [[ "$ENCRYPTION_ENABLED" == "true" && -f "$SECURITY_SCRIPT" ]]; then
    echo "Would you like to encrypt this entry? (y/n)"
    read encrypt_entry
    
    if [[ "$encrypt_entry" == "y" || "$encrypt_entry" == "Y" ]]; then
      # Encrypt the entry
      encrypted_content=$("$SECURITY_SCRIPT" encrypt "$entry_content")
      if [[ $? -eq 0 ]]; then
        entry_content="$encrypted_content"
        is_encrypted=true
      else
        echo "Encryption failed. Saving entry without encryption."
      fi
    fi
  fi
  
  # Save the entry to file
  if [[ ! -f "$file_path" ]]; then
    # Create new file with header if it doesn't exist
    echo "# Journal Entries for $(date +"%B %Y")\n\n" > "$file_path"
  fi
  
  # Append the entry to the file
  echo "$entry_content" >> "$file_path"
  
  if [[ "$is_encrypted" == "true" ]]; then
    echo "✅ Encrypted journal entry saved to $file_path"
  else
    echo "✅ Journal entry saved to $file_path"
  fi

  # Commit changes if git is enabled
  if [[ "$GIT_ENABLED" == "true" && "$GIT_AUTO_COMMIT" == "true" && -f "$GIT_SCRIPT" ]]; then
    echo "Committing changes to git repository..."
    "$GIT_SCRIPT" commit
  fi
  
  # Show a random quote after journaling if quotes are enabled
  if [[ "$QUOTES_ENABLED" == "true" && -f "$QUOTE_SCRIPT" ]]; then
    echo ""
    echo "Here's an inspirational quote for you:"
    "$QUOTE_SCRIPT" random
  fi
}

# ============================
# Function to list entries
# ============================
function list_journals() {
  echo "📚 Available Journal Months:"
  print_line
  
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
    
    # Count encrypted entries
    local encrypted_count=$(grep -c "<!-- ENCRYPTED ENTRY -->" "$file")
    
    # Format month for display
    local display_month=$(format_month "$month")
    
    echo "📔 $display_month: $entry_count entries ($coding_count coding, $personal_count personal, $encrypted_count encrypted)"
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
  
  # Format month for display
  local display_month=$(format_month "$month")
  
  echo "📖 Viewing entries for $display_month"
  echo ""
  
  # Check if file contains encrypted entries
  if grep -q "<!-- ENCRYPTED ENTRY -->" "$file_path" && [[ -f "$SECURITY_SCRIPT" ]]; then
    echo "This file contains encrypted entries."
    echo "Would you like to decrypt them? (y/n)"
    read decrypt_entries
    
    if [[ "$decrypt_entries" == "y" || "$decrypt_entries" == "Y" ]]; then
      # Create a temporary file for decrypted content
      local temp_file=$(mktemp)
      
      # Copy original file to temp file
      cp "$file_path" "$temp_file"
      
      # Get password once
      echo "Please enter your encryption password:"
      read -s password
      
      # Find all encrypted entries - use a more reliable approach
      grep -n "<!-- ENCRYPTED ENTRY -->" "$temp_file" | while IFS=: read -r line_num marker; do
        # Calculate start and end lines more carefully
        local start_line=$((line_num + 1))
        
        # Find the next entry marker or end of file
        local next_marker=$(tail -n +$((start_line)) "$temp_file" | grep -n "^## \|<!-- ENCRYPTED ENTRY -->" | head -1)
        
        if [[ -n "$next_marker" ]]; then
          # Extract line number of the next marker relative to start_line
          local relative_lines=$(echo "$next_marker" | cut -d: -f1)
          local end_line=$((start_line + relative_lines - 1))
        else
          # If no next marker, go to end of file
          end_line=$(wc -l < "$temp_file")
        fi
        
        # Extract the encrypted content
        local encrypted_content=$(sed -n "${start_line},${end_line}p" "$temp_file")
        
        # Trim any leading/trailing whitespace
        encrypted_content=$(echo "$encrypted_content" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        if [[ -n "$encrypted_content" ]]; then
          # Attempt to decrypt the content
          local decrypted_content=$("$SECURITY_SCRIPT" decrypt "$encrypted_content" 2>/dev/null)
          local decrypt_status=$?
          
          if [[ $decrypt_status -eq 0 && -n "$decrypted_content" ]]; then
            # Success - replace content in the temp file
            # First, remove encryption marker
            sed -i.bak "${line_num}d" "$temp_file"
            
            # Now replace encrypted content with decrypted
            # Using a temporary replacement file to avoid sed issues with newlines
            local replace_file=$(mktemp)
            echo "$decrypted_content" > "$replace_file"
            
            # Adjust line numbers after deletion of marker
            start_line=$((start_line - 1))
            end_line=$((end_line - 1))
            
            # Delete encrypted content lines
            sed -i.bak "${start_line},${end_line}d" "$temp_file"
            
            # Insert decrypted content
            sed -i.bak "${start_line}r $replace_file" "$temp_file"
            
            # Clean up
            rm "$replace_file"
          else
            # Decryption failed - replace with a message
            sed -i.bak "${line_num}c\\
<!-- ENCRYPTED ENTRY (Decryption failed) -->" "$temp_file"
            sed -i.bak "${start_line},${end_line}c\\
*This entry could not be decrypted. The password may be incorrect.*" "$temp_file"
          fi
        fi
      done
      
      # View the modified file
      less -R "$temp_file"
      
      # Clean up
      rm "$temp_file" "$temp_file.bak" 2>/dev/null
      return 0
    fi
  fi
  
  # If no decryption needed or requested, just view the file normally
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
    local display_month=$(format_month "$month")
    
    # Skip encrypted content in search
    if grep -q "<!-- ENCRYPTED ENTRY -->" "$file"; then
      echo "📔 $display_month: Contains encrypted entries (not searched)"
      continue
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
    echo "Note: Encrypted entries were not searched."
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
  local encrypted_entries=0
  
  for file in "${files[@]}"; do
    # Count entries in each file
    local file_entries=$(grep -c "^## " "$file")
    local file_coding=$(grep -c "^## Coding Session" "$file")
    local file_personal=$(grep -c "^## Personal Reflection" "$file")
    local file_encrypted=$(grep -c "<!-- ENCRYPTED ENTRY -->" "$file")
    
    total_entries=$((total_entries + file_entries))
    coding_entries=$((coding_entries + file_coding))
    personal_entries=$((personal_entries + file_personal))
    encrypted_entries=$((encrypted_entries + file_encrypted))
  done
  
  echo "Total journal entries: $total_entries"
  echo "Coding journal entries: $coding_entries"
  echo "Personal journal entries: $personal_entries"
  echo "Encrypted entries: $encrypted_entries"
  
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
    local display_month=$(format_month "$most_active_month")
    echo "Most active month: $display_month ($most_active_count entries)"
  fi
  
  # Display encryption status
  if [[ "$ENCRYPTION_ENABLED" == "true" ]]; then
    echo "Encryption is enabled"
    echo "Encrypted entries: $encrypted_entries ($(( encrypted_entries * 100 / total_entries ))%)"
  else
    echo "Encryption is not enabled"
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
elif [[ "$1" == "quote" ]]; then
  # Quote system commands
  if [[ -f "$QUOTE_SCRIPT" ]]; then
    # Pass all arguments to the quote script
    shift  # Remove the "quote" argument
    "$QUOTE_SCRIPT" "$@"
  else
    echo "Quote manager not found. Please run setup script first."
    exit 1
  fi
elif [[ "$1" == "security" ]]; then
  # Security and encryption commands
  if [[ -f "$SECURITY_SCRIPT" ]]; then
    # Pass all arguments to the security script
    shift  # Remove the "security" argument
    "$SECURITY_SCRIPT" "$@"
  else
    echo "Security manager not found. Please run setup script first."
    exit 1
  fi
elif [[ "$1" == "git" ]]; then
  # Git integration commands
  if [[ -f "$GIT_SCRIPT" ]]; then
    # Pass all arguments to the git script
    shift  # Remove the "git" argument
    "$GIT_SCRIPT" "$@"
  else
    echo "Git manager not found. Please run setup script first."
    exit 1
  fi
elif [[ "$1" == "test" ]]; then
  # Test system compatibility
  if [[ -f "$UTILS_SCRIPT" ]]; then
    "$UTILS_SCRIPT"
  else
    echo "Utility script not found. Cannot run tests."
    exit 1
  fi
elif [[ "$1" == "--post-ide" ]]; then
  # Called after IDE closes (same as coding)
  create_journal_entry "coding"
elif [[ "$1" == "help" || "$1" == "--help" ]]; then

  # =========================
  # Display help information
  # =========================
  echo "Usage: journash [COMMAND]"
  echo "A simple CLI journaling system."
  echo ""
  echo "Commands:"
  echo "  code, coding       Create a coding journal entry"
  echo "  personal           Create a personal journal entry"
  echo "  view               List all available journals"
  echo "  view YYYY-MM       View entries for specific month"
  echo "  search TERM        Search for a term across all entries"
  echo "  stats              Show journal statistics"
  echo "  quote              Manage inspirational quotes"
  echo "  security           Manage encryption for private entries"
  echo "  git                Manage git repository for backups"
  echo "  test               Test system compatibility"
  echo "  help               Show this help message"
  echo ""
  echo "Examples:"
  echo "  journash code                # Create a coding journal entry"
  echo "  journash personal            # Create a personal journal entry"
  echo "  journash view                # List all available journals"
  echo "  journash view 04-2025        # View entries from April 2025"
  echo "  journash search \"python\"     # Search for entries containing 'python'"
  echo "  journash quote add           # Add a new quote"
  echo "  journash security setup      # Set up encryption for private entries"
  echo "  journash git init            # Initialize git repository for backups"
  exit 0
else
  # Unknown argument
  echo "Unknown command: $1"
  echo "Try 'journash help' for more information."
  exit 1
fi