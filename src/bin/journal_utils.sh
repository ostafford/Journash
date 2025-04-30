#!/bin/zsh

# Journash - Coding Journal CLI
# Utility functions for cross-platform compatibility

# Detect operating system
function detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  elif [[ "$(uname)" == "Linux" ]]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

# Format date based on OS
function format_date() {
  local date_str=$1
  local format=$2
  local os=$(detect_os)
  
  if [[ "$os" == "macos" ]]; then
    # macOS date command
    date -j -f "%Y-%m-%d" "$date_str" "$format" 2>/dev/null || echo "$date_str"
  elif [[ "$os" == "linux" ]]; then
    # Linux date command
    date -d "$date_str" "$format" 2>/dev/null || echo "$date_str"
  else
    # Fallback
    echo "$date_str"
  fi
}

# Format month based on OS
function format_month() {
  local month=$1
  local os=$(detect_os)
  
  if [[ "$os" == "macos" ]]; then
    # macOS date command
    date -j -f "%Y-%m" "$month" "+%B %Y" 2>/dev/null || echo "$month"
  elif [[ "$os" == "linux" ]]; then
    # Linux date command
    date -d "$month-01" "+%B %Y" 2>/dev/null || echo "$month"
  else
    # Fallback
    echo "$month"
  fi
}

# Show system notification based on OS
function show_notification() {
  local title=$1
  local message=$2
  local os=$(detect_os)
  
  if [[ "$os" == "macos" ]]; then
    # macOS notification
    osascript -e "display notification \"$message\" with title \"$title\""
  elif [[ "$os" == "linux" ]]; then
    # Linux notification (works on most desktop environments)
    if command -v notify-send &> /dev/null; then
      notify-send "$title" "$message"
    else
      echo "$title: $message" # Fallback to console
    fi
  else
    # Fallback to console
    echo "$title: $message"
  fi
}

# Check if a command exists
function command_exists() {
  command -v "$1" &> /dev/null
}

# Get terminal width
function get_terminal_width() {
  local os=$(detect_os)
  local width=80 # Default fallback
  
  if command_exists tput; then
    width=$(tput cols)
  elif command_exists stty; then
    width=$(stty size | cut -d' ' -f2)
  fi
  
  echo $width
}

# Print a horizontal line
function print_line() {
  local width=$(get_terminal_width)
  printf "%0.s-" $(seq 1 $width)
  echo ""
}

# Print centered text
function print_centered() {
  local text=$1
  local width=$(get_terminal_width)
  local padding=$(( (width - ${#text}) / 2 ))
  
  printf "%${padding}s" ""
  echo "$text"
}

# Test system compatibility
function test_compatibility() {
  local os=$(detect_os)
  echo "Detecting system compatibility..."
  echo "Operating System: $os"
  
  # Check for required commands
  echo "Testing required commands:"
  
  local all_commands_available=true
  local required_commands=("grep" "sed" "less" "cat")
  
  for cmd in "${required_commands[@]}"; do
    if command_exists "$cmd"; then
      echo "✅ $cmd: Available"
    else
      echo "❌ $cmd: Not found"
      all_commands_available=false
    fi
  done
  
  # Test notification system
  echo "Testing notification system..."
  if [[ "$os" == "macos" ]]; then
    if command_exists osascript; then
      echo "✅ Notification system: Available"
      show_notification "Journash Test" "Notification system is working!"
    else
      echo "❌ Notification system: Not available"
    fi
  elif [[ "$os" == "linux" ]]; then
    if command_exists notify-send; then
      echo "✅ Notification system: Available"
      show_notification "Journash Test" "Notification system is working!"
    else
      echo "❌ Notification system: Not available"
    fi
  else
    echo "❓ Notification system: Unknown"
  fi
  
  # Test date formatting
  echo "Testing date formatting..."
  local test_date="2023-01-15"
  local formatted_date=$(format_date "$test_date" "+%B %d, %Y")
  echo "Sample date conversion: $test_date -> $formatted_date"
  
  if [[ "$all_commands_available" == true ]]; then
    echo "✅ All required commands are available"
    return 0
  else
    echo "❌ Some required commands are missing"
    return 1
  fi
}

# If the script is called directly, run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  test_compatibility
fi