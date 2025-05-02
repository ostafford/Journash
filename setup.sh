#!/bin/zsh

# Journash - Coding Journal CLI
# Setup script to establish directory structure

echo "🚀 Setting up Journash - Coding Journal CLI..."

# Define the main directory for the journal
JOURNAL_DIR="$HOME/.coding_journal"

# Create main directory if it doesn't exist
if [[ ! -d "$JOURNAL_DIR" ]]; then
  echo "Creating main directory: $JOURNAL_DIR"
  mkdir -p "$JOURNAL_DIR"
else
  echo "Main directory already exists: $JOURNAL_DIR"
fi

# Create subdirectories
for dir in "bin" "data" "config"; do
  if [[ ! -d "$JOURNAL_DIR/$dir" ]]; then
    echo "Creating directory: $JOURNAL_DIR/$dir"
    mkdir -p "$JOURNAL_DIR/$dir"
  else
    echo "Directory already exists: $JOURNAL_DIR/$dir"
  fi
done

# Create default settings.conf if it doesn't exist
SETTINGS_FILE="$JOURNAL_DIR/config/settings.conf"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "Creating default settings file: $SETTINGS_FILE"
  cat > "$SETTINGS_FILE" << EOF
# Journash Configuration File

# IDE Settings
IDE_COMMAND="cursor"        # Command to open the IDE
IDE_ARGS="--wait"           # Arguments for the IDE command
TERMINAL_EMULATOR="iterm"   # Terminal emulator (iterm, gnome-terminal, konsole, etc.)

# Journal Settings
AUTO_JOURNAL_ENABLED=true       # Enable/disable auto-journaling after IDE closes
JOURNAL_FILE_FORMAT="%Y-%m.md"  # Date format for journal files

# Appearance
PROMPT_SYMBOL="📝"              # Symbol to use in journal prompts
EOF
  echo "Default settings configured."
else
  echo "Settings file already exists: $SETTINGS_FILE"
fi

# Copy main script files to bin directory
SCRIPT_FILES=(
  "journal_main.sh"
  "journal_utils.sh"
  "journal_git.sh"
  "journal_entry.sh"
  "journal_view.sh"
  "journal_search.sh"
  "journal_stats.sh"
)

for script in "${SCRIPT_FILES[@]}"; do
  SRC_SCRIPT="./src/bin/$script"
  DEST_SCRIPT="$JOURNAL_DIR/bin/$script"
  
  if [[ -f "$SRC_SCRIPT" ]]; then
    echo "Copying $script to: $DEST_SCRIPT"
    cp "$SRC_SCRIPT" "$DEST_SCRIPT"
    chmod +x "$DEST_SCRIPT"
  else
    echo "Warning: Script not found at $SRC_SCRIPT"
    echo "Please create the script file first."
  fi
done

# Check if Zsh integration already exists
if ! grep -q "# Journash Integration" "$HOME/.zshrc"; then
  echo "Setting up Zsh integration..."
  
  # Add integration to zshrc
  cat >> "$HOME/.zshrc" << 'EOF'

# Journash Integration
# Function to allow 'journash' command
function journash() {
  "$HOME/.coding_journal/bin/journal_main.sh" "$@"
}

function code_journal() {
  # Source utility script for OS detection if available
  if [[ -f "$HOME/.coding_journal/bin/journal_utils.sh" ]]; then
    source "$HOME/.coding_journal/bin/journal_utils.sh"
  else
    function detect_os() { 
      if [[ "$(uname)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi 
    }
  fi
  
  # Source settings for IDE preferences
  if [[ -f "$HOME/.coding_journal/config/settings.conf" ]]; then
    source "$HOME/.coding_journal/config/settings.conf"
  else
    # Default settings if not found
    IDE_COMMAND="cursor"
    IDE_ARGS="--wait"
    TERMINAL_EMULATOR="iterm"
  fi
  
  # Function to display post-IDE message and trigger journal
  function post_ide_journal() {
    clear
    echo -e "\033[1;36m=============================\033[0m"
    echo -e "\033[1;32m ✨ Coding session completed \033[0m"
    echo -e "\033[1;36m=============================\033[0m"
    echo ""
    journash --post-ide
  }

  # Run the IDE opening and journal process in the background
  (
    # Create a trap to ensure temporary files are cleaned up
    function cleanup_temp_files() {
      if [[ -n "$tmp_script" && -f "$tmp_script" ]]; then
        rm -f "$tmp_script"
      fi
    }
    # Set trap to call cleanup function on exit, interrupt, or termination
    trap cleanup_temp_files EXIT INT TERM
    
    # Open the IDE with the configured command
    $IDE_COMMAND $IDE_ARGS "$@"
    
    # After IDE closes, open a terminal for journaling based on OS
    local os=$(detect_os)
    
    if [[ "$os" == "macos" ]]; then
      # macOS using AppleScript
      if [[ "$TERMINAL_EMULATOR" == "iterm" ]]; then
        # Create a temporary script file securely
        tmp_script=$(mktemp "${TMPDIR:-/tmp}/journash_post_ide_XXXXXX.sh")
        
        # Make it executable
        chmod 700 "$tmp_script"
        
        # Add content to the script - FIXED the nested cat issue
        cat > "$tmp_script" << EOFSCRIPT
#!/bin/zsh
clear
echo -e "\033[1;36m=============================\033[0m"
echo -e "\033[1;32m ✨ Coding session completed \033[0m"
echo -e "\033[1;36m=============================\033[0m"
echo ""
EOFSCRIPT
        
        # Launch iTerm with the script
        osascript -e "tell application \"iTerm\"
          create window with default profile
          tell current window
            tell current session
              write text \"$tmp_script; journash --post-ide\"
            end tell
          end tell
        end tell"
        
        # Small delay to ensure the script has been loaded
        sleep 1
        
        # Cleanup is handled by the trap, we don't need to manually remove it here
      elif [[ "$TERMINAL_EMULATOR" == "terminal" ]]; then
        # Alternative for Terminal.app
        osascript -e "tell application \"Terminal\" to do script \"journash --post-ide\""
      else
        # Fallback to command line
        post_ide_journal
      fi
    else
      # Linux using various terminal emulators
      if [[ "$TERMINAL_EMULATOR" == "gnome-terminal" ]]; then
        gnome-terminal -- bash -c "$(declare -f post_ide_journal); post_ide_journal; exec bash"
      elif [[ "$TERMINAL_EMULATOR" == "konsole" ]]; then
        konsole --noclose -e bash -c "$(declare -f post_ide_journal); post_ide_journal"
      elif [[ "$TERMINAL_EMULATOR" == "xterm" ]]; then
        xterm -e "$(declare -f post_ide_journal); post_ide_journal; bash"
      else
        # Fallback to command line
        post_ide_journal
      fi
    fi
  ) &
  
  # Disown the process so it continues running even if terminal is closed
  disown
  
  echo "IDE launched in background. Journal entry will be prompted when IDE closes."
}
# End Journash Integration

EOF

  echo "✅ Zsh integration complete!"
  echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
else
  echo "Journash integration already exists in ~/.zshrc"
fi

# Create a sample journal entry for testing if no entries exist
if [[ ! -f "$JOURNAL_DIR/data/$(date +%Y-%m).md" ]]; then
  echo "Creating a sample journal entry for testing..."
  
  # Format the current month and year
  MONTH_YEAR=$(date +"%B %Y")
  
  # Create the file with a header
  cat > "$JOURNAL_DIR/data/$(date +%Y-%m).md" << EOF
# Coding Journal Entries for $MONTH_YEAR

## Coding Session - $(date +"%Y-%m-%d %H:%M")

**Duration**: 1h 30m

**Worked on**: 
Setting up Journash, a CLI journaling system for tracking coding progress.

**Challenges**: 
Getting cross-platform compatibility working between macOS and Linux.

**Solutions**: 
Created utility functions that detect the OS and adapt commands accordingly.

**Learned**: 
AppleScript can be used to open new terminal windows with specific commands.

**Next Steps**: 
Test the system with daily use and improve error handling.

---

EOF

  echo "Sample entry created."
fi

# Test system compatibility
echo "Testing system compatibility..."
"$JOURNAL_DIR/bin/journal_utils.sh"

# Check for required utilities
echo "Checking for required utilities..."

# Check for Git (required for version control)
if ! command -v git &> /dev/null; then
  echo "⚠️ Warning: Git is not installed. Version control features will not be available."
  echo "Please install Git to use backup and versioning features."
else
  echo "✅ Git is available. Version control features can be used."
fi

# Feature setup questions
echo ""
echo "Would you like to set up Git repository for version control and backups? (y/n)"
read setup_git

if [[ "$setup_git" == "y" || "$setup_git" == "Y" ]]; then
  # Check if Git is available
  if command -v git &> /dev/null; then
    "$JOURNAL_DIR/bin/journal_git.sh" init
    
    echo "Would you like to set up a remote repository for cloud backup? (y/n)"
    read setup_remote
    
    if [[ "$setup_remote" == "y" || "$setup_remote" == "Y" ]]; then
      echo "Please enter the URL of your remote repository:"
      read remote_url
      
      if [[ -n "$remote_url" ]]; then
        "$JOURNAL_DIR/bin/journal_git.sh" remote "$remote_url"
      fi
    fi
  else
    echo "❌ Cannot set up Git repository: Git is not installed."
    echo "Please install Git and run 'journash git init' later."
  fi
fi

echo "✅ Journash setup complete!"
echo "You can now use 'journash' to create coding journal entries."
echo "Try 'journash help' to see all available commands."
echo ""
echo "Quick start:"
echo "  journash                - Create a coding journal entry"
echo "  journash view           - View your journal entries"
echo "  journash git            - Manage git repository for backups"
echo ""
echo "For automatic journaling when closing your IDE:"
echo "  Use 'code_journal' instead of your normal IDE command to launch your IDE"
echo "  For example: code_journal ~/projects/my-capstone-project"