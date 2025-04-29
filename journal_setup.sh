#!/bin/bash
# journal_setup.sh - Setup script for Coding Journal CLI
# This script creates the necessary directory structure and performs initial setup

# Terminal colors for better feedback
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print a colored message
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Main directory paths
JOURNAL_DIR="$HOME/.coding_journal"
BIN_DIR="$JOURNAL_DIR/bin"
DATA_DIR="$JOURNAL_DIR/data"
CONFIG_DIR="$JOURNAL_DIR/config"

# Welcome message
echo "==============================================="
echo "  Coding Journal CLI - Setup"
echo "==============================================="
echo ""

# Check for required commands
print_message "$YELLOW" "Checking requirements..."

missing_deps=0
for cmd in grep sed awk; do
  if ! command_exists $cmd; then
    print_message "$RED" "❌ Required command '$cmd' not found."
    missing_deps=1
  fi
done

if [ $missing_deps -eq 1 ]; then
  print_message "$RED" "Please install the missing dependencies and run setup again."
  exit 1
else
  print_message "$GREEN" "✅ All required commands are available."
fi

# Create directory structure
print_message "$YELLOW" "Creating directory structure..."

# Create main directory if it doesn't exist
if [ ! -d "$JOURNAL_DIR" ]; then
  mkdir -p "$JOURNAL_DIR"
  print_message "$GREEN" "✅ Created main directory: $JOURNAL_DIR"
else
  print_message "$YELLOW" "📁 Main directory already exists: $JOURNAL_DIR"
fi

# Create subdirectories
for dir in "$BIN_DIR" "$DATA_DIR" "$CONFIG_DIR"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    print_message "$GREEN" "✅ Created directory: $dir"
  else
    print_message "$YELLOW" "📁 Directory already exists: $dir"
  fi
done

# Create quotes file if it doesn't exist
QUOTES_FILE="$DATA_DIR/quotes.txt"
if [ ! -f "$QUOTES_FILE" ]; then
  touch "$QUOTES_FILE"
  # Add a sample quote
  echo "$(date +%d-%m-%Y)|\"The best way to predict the future is to invent it.\" - Alan Kay" > "$QUOTES_FILE"
  print_message "$GREEN" "✅ Created quotes file with sample quote."
else
  print_message "$YELLOW" "📄 Quotes file already exists."
fi

# Setup complete
print_message "$GREEN" "✅ Directory setup complete!"
echo ""
print_message "$YELLOW" "Next steps:"
echo "1. Create configuration files"
echo "2. Implement journal functionality"
echo "3. Configure shell integration"
echo ""