#!/bin/zsh

# Journash - Coding Journal CLI
# Quote management system

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"
QUOTES_FILE="$DATA_DIR/quotes.txt"

# Source utility functions if available
if [[ -f "$UTILS_SCRIPT" ]]; then
  source "$UTILS_SCRIPT"
else
  echo "Warning: Utility script not found at $UTILS_SCRIPT"
  # Fallback for critical functions
  function show_notification() { echo "$1: $2"; }
  function print_line() { echo "----------------------"; }
fi

# Source settings if they exist
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

# Function to add a new quote
function add_quote() {
  # Get the quote from the user
  echo "Enter your new programming quote:"
  echo "Format: \"Quote text here\" - Author Name"
  echo "(Press Ctrl+D on a new line when finished)"
  
  quote_text=$(cat)
  
  # Validate the quote
  if [[ -z "$quote_text" ]]; then
    echo "❌ Quote cannot be empty."
    return 1
  fi
  
  # Add the quote with today's date
  echo "$(date +%Y-%m-%d)|$quote_text" >> "$QUOTES_FILE"
  
  echo "✅ Quote added successfully!"
  echo "Use 'journash quote show' to see all quotes."
}

# Function to list all quotes
function list_quotes() {
  echo "📜 Your Quotes Collection"
  print_line
  
  if [[ ! -f "$QUOTES_FILE" || ! -s "$QUOTES_FILE" ]]; then
    echo "No quotes found. Add some with 'journash quote add'."
    return 1
  fi
  
  local quote_count=0
  
  # Read and display each quote
  while IFS='|' read -r date quote; do
    echo "📅 $date"
    echo "💬 $quote"
    echo ""
    
    quote_count=$((quote_count + 1))
  done < "$QUOTES_FILE"
  
  echo "Total quotes: $quote_count"
}

# Function to display a random quote
function show_random_quote() {
  if [[ ! -f "$QUOTES_FILE" || ! -s "$QUOTES_FILE" ]]; then
    echo "No quotes found. Add some with 'journash quote add'."
    return 1
  fi
  
  # Count lines in the file
  local line_count=$(wc -l < "$QUOTES_FILE")
  
  # Generate a random number between 1 and line_count
  local random_line=$((RANDOM % line_count + 1))
  
  # Get the random quote
  local random_quote=$(sed -n "${random_line}p" "$QUOTES_FILE")
  
  # Split the quote into date and text
  local date=$(echo "$random_quote" | cut -d'|' -f1)
  local quote=$(echo "$random_quote" | cut -d'|' -f2-)
  
  if [[ "$1" == "notify" ]]; then
    # Show as a notification
    show_notification "💬 Coding Inspiration" "$quote"
  else
    # Display in the terminal
    echo "💬 Random Inspiration:"
    echo "$quote"
    echo "📅 Added on: $date"
  fi
}

# Function to schedule notifications
function schedule_notifications() {
  local os=$(detect_os)
  
  if [[ "$QUOTES_ENABLED" != "true" ]]; then
    echo "Quote notifications are disabled in settings."
    echo "To enable, set QUOTES_ENABLED=true in $SETTINGS_FILE"
    return 1
  fi
  
  echo "Setting up quote notifications every $QUOTE_FREQUENCY hours..."
  
  if [[ "$os" == "macos" ]]; then
    # Schedule with launchd on macOS
    local plist_file="$HOME/Library/LaunchAgents/com.journash.quotes.plist"
    local plist_dir=$(dirname "$plist_file")
    
    # Create directory if it doesn't exist
    if [[ ! -d "$plist_dir" ]]; then
      mkdir -p "$plist_dir"
    fi
    
    # Create the plist file
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.journash.quotes</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_DIR/quote_manager.sh</string>
        <string>random</string>
        <string>notify</string>
    </array>
    <key>StartInterval</key>
    <integer>$(($QUOTE_FREQUENCY * 3600))</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    
    # Load the plist
    launchctl unload "$plist_file" 2>/dev/null
    launchctl load "$plist_file"
    
    echo "✅ Notifications scheduled using launchd."
    echo "You will receive quotes every $QUOTE_FREQUENCY hours."
    
  elif [[ "$os" == "linux" ]]; then
    # Schedule with cron on Linux
    if ! command_exists crontab; then
      echo "❌ crontab command not found. Please install cron."
      return 1
    fi
    
    # Create a temporary file for the crontab entry
    local temp_file=$(mktemp)
    
    # Export current crontab
    crontab -l > "$temp_file" 2>/dev/null
    
    # Remove any existing Journash quote entries
    sed -i '/# Journash quote notification/d' "$temp_file"
    sed -i '/quote_manager.sh random notify/d' "$temp_file"
    
    # Add the new entry
    echo "0 */$QUOTE_FREQUENCY * * * $BIN_DIR/quote_manager.sh random notify # Journash quote notification" >> "$temp_file"
    
    # Install the new crontab
    crontab "$temp_file"
    rm "$temp_file"
    
    echo "✅ Notifications scheduled using cron."
    echo "You will receive quotes every $QUOTE_FREQUENCY hours."
    
  else
    echo "❌ Unsupported operating system. Cannot schedule notifications."
    return 1
  fi
  
  # Show a test notification
  echo "Displaying test notification..."
  show_random_quote "notify"
}

# Process command line arguments
if [[ $# -eq 0 || "$1" == "help" ]]; then
  # Display help information
  echo "Usage: journash quote [COMMAND]"
  echo "Manage and display inspirational coding quotes."
  echo ""
  echo "Commands:"
  echo "  add              Add a new quote"
  echo "  show             List all quotes"
  echo "  random           Show a random quote"
  echo "  schedule         Set up scheduled notifications"
  echo "  help             Show this help message"
  echo ""
  echo "Examples:"
  echo "  journash quote add       # Add a new quote"
  echo "  journash quote random    # Display a random quote"
elif [[ "$1" == "add" ]]; then
  add_quote
elif [[ "$1" == "show" ]]; then
  list_quotes
elif [[ "$1" == "random" ]]; then
  if [[ "$2" == "notify" ]]; then
    show_random_quote "notify"
  else
    show_random_quote
  fi
elif [[ "$1" == "schedule" ]]; then
  schedule_notifications
else
  echo "Unknown command: $1"
  echo "Try 'journash quote help' for more information."
  exit 1
fi