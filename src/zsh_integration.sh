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
  
# IDE wrapper function for auto-journaling
function code_journal() {
  # Run the IDE opening and journal process in the background
  (
    # Open Cursor with the --wait flag to block until it closes
    cursor --wait "$@"
    
    # After Cursor closes, open a new iTerm window with colors
    osascript -e '
      tell application "iTerm"
        create window with default profile
        tell current window
          tell current session
            # Use proper escaping for both AppleScript and shell
            write text "clear && echo \"\\033[1;36m=============================\\033[0m\" && echo \"\\033[1;32m ✨ Coding session completed\\033[0m\" && echo \"\\033[1;36m=============================\\033[0m\" && echo \"\" && journash --post-ide"
          end tell
        end tell
      end tell
    '
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