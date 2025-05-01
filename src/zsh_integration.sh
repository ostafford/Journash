#!/bin/zsh

# Journash - Coding Journal CLI
# Zsh integration script

echo "🔄 Setting up Zsh integration for Journash..."

# Path to zshrc file
ZSHRC_FILE="$HOME/.zshrc"

# Path to journal main script
JOURNAL_SCRIPT="$HOME/.coding_journal/bin/journal_main.sh"

# Check if zshrc exists
if [[ ! -f "$ZSHRC_FILE" ]]; then
  echo "Error: $ZSHRC_FILE not found."
  exit 1
fi

# Check if journal script exists
if [[ ! -f "$JOURNAL_SCRIPT" ]]; then
  echo "Error: Journal script not found at $JOURNAL_SCRIPT"
  echo "Please run setup script first."
  exit 1
fi

# Check if integration already exists
if grep -q "# Journash Integration" "$ZSHRC_FILE"; then
  echo "Journash integration already exists in $ZSHRC_FILE"
  echo "No changes made."
  exit 0
fi

# Add integration to zshrc
echo "Adding Journash integration to $ZSHRC_FILE"

cat >> "$ZSHRC_FILE" << EOF

# Journash Integration
# Function to allow 'journash' command (unique name to avoid conflicts)
function journash() {
  $JOURNAL_SCRIPT "\$@"
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
    echo -e "\033[1;32m ✨ Coding session completed\033[0m"
    echo -e "\033[1;36m=============================\033[0m"
    echo ""
    journash --post-ide
  }
  
  # Run the IDE opening and journal process in the background
  (
    # Open the IDE with the configured command
    $IDE_COMMAND $IDE_ARGS "$@"
    
    # After IDE closes, open a terminal for journaling based on OS
    local os=$(detect_os)
    
    if [[ "$os" == "macos" ]]; then
      # macOS using AppleScript
      if [[ "$TERMINAL_EMULATOR" == "iterm" ]]; then
        # Create a temporary script file to avoid quote issues
        local tmp_script="/tmp/journash_post_ide_$$.sh"
        echo '#!/bin/zsh
clear
echo -e "\033[1;36m=============================\033[0m"
echo -e "\033[1;32m ✨ Coding session completed\033[0m"
echo -e "\033[1;36m=============================\033[0m"
echo ""
journash --post-ide
' > "$tmp_script"
        chmod +x "$tmp_script"
        
        # Launch iTerm with the script
        osascript -e "tell application \"iTerm\"
          create window with default profile
            tell current window
              tell current session
                write text \"$tmp_script\"
              end tell
            end tell
          end tell"
        
        # Clean up
        sleep 3
        rm "$tmp_script"
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
echo "Please restart your terminal or run 'source $ZSHRC_FILE' to apply changes."
echo "You can now use 'journash' to create journal entries."
echo "Use 'code_journal' instead of 'code' to enable auto-journaling when VS Code closes."