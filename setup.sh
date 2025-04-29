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

# Create empty quotes file if it doesn't exist
QUOTES_FILE="$JOURNAL_DIR/data/quotes.txt"
if [[ ! -f "$QUOTES_FILE" ]]; then
  echo "Creating empty quotes file: $QUOTES_FILE"
  touch "$QUOTES_FILE"
  # Add a sample quote
  echo "$(date +%Y-%m-%d)|\"The best way to predict the future is to invent it.\" - Alan Kay" > "$QUOTES_FILE"
else
  echo "Quotes file already exists: $QUOTES_FILE"
fi

# =================================================
# Create default settings.conf if it doesn't exist
# =================================================
SETTINGS_FILE="$JOURNAL_DIR/config/settings.conf"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "Creating default settings file: $SETTINGS_FILE"
  cat > "$SETTINGS_FILE" << EOF
# Journash Configuration File

# Journal Settings
AUTO_JOURNAL_ENABLED=true       # Enable/disable auto-journaling after IDE closes
JOURNAL_FILE_FORMAT="%Y-%m.md"  # Date format for journal files

# Quote Settings
QUOTES_ENABLED=true             # Enable/disable quotes system
QUOTE_FREQUENCY=4               # Hours between quote notifications

# Appearance
PROMPT_SYMBOL="📝"              # Symbol to use in journal prompts
EOF
  echo "Default settings configured."
else
  echo "Settings file already exists: $SETTINGS_FILE"
fi

# =================================================
# Create empty security.conf file for future use
# =================================================
SECURITY_FILE="$JOURNAL_DIR/config/security.conf"
if [[ ! -f "$SECURITY_FILE" ]]; then
  echo "Creating security configuration file: $SECURITY_FILE"
  cat > "$SECURITY_FILE" << EOF
# Journash Security Configuration

# Encryption Settings
ENCRYPTION_ENABLED=false        # Enable/disable encryption for private entries
# PASSWORD_HASH=                # Will be set when password is created
EOF
  echo "Security configuration initialized."
else
  echo "Security file already exists: $SECURITY_FILE"
fi

MAIN_SCRIPT="./src/bin/journal_main.sh"
DEST_SCRIPT="$JOURNAL_DIR/bin/journal_main.sh"

if [[ -f "$MAIN_SCRIPT" ]]; then
  echo "Copying main script to: $DEST_SCRIPT"
  cp "$MAIN_SCRIPT" "$DEST_SCRIPT"
  chmod +x "$DEST_SCRIPT"
else
  echo "Warning: Main script not found at $MAIN_SCRIPT"
  echo "Please create the script file first."
fi

# =================================================
# Run Zsh integration script if it exists
# =================================================
ZSH_INTEGRATION="./src/zsh_integration.sh"
if [[ -f "$ZSH_INTEGRATION" ]]; then
  echo "Setting up Zsh integration..."
  chmod +x "$ZSH_INTEGRATION"
  "$ZSH_INTEGRATION"
else
  echo "Warning: Zsh integration script not found at $ZSH_INTEGRATION"
  echo "Please create the script file first."
fi

echo "✅ Directory structure setup complete!"
echo "Next steps: Creating configuration files..."