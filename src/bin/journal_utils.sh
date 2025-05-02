#!/bin/zsh

# Journash - Coding Journal CLI
# Utility functions for cross-platform compatibility and logging

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
LOG_FILE="$JOURNAL_DIR/journash.log"

# ======================================
# Logging functions
# ======================================

# Function to log messages with timestamp
# Usage: log_message "INFO" "Message here"
function log_message() {
  local level=$1
  local message=$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Create log directory if it doesn't exist
  if [[ ! -d "$(dirname "$LOG_FILE")" ]]; then
    mkdir -p "$(dirname "$LOG_FILE")"
  fi
  
  # Append log message to log file
  echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  
  # Print to stdout if verbose mode is enabled
  if [[ "${VERBOSE_LOGGING:-false}" == "true" ]]; then
    echo "[$level] $message"
  fi
}

# Function to log an info message
# Usage: log_info "Message here"
function log_info() {
  log_message "INFO" "$1"
}

# Function to log a warning message
# Usage: log_warning "Warning message here"
function log_warning() {
  log_message "WARNING" "$1"
  # Print warnings to stdout regardless of verbose setting
  echo "⚠️ WARNING: $1"
}

# Function to log an error message
# Usage: log_error "Error message here"
function log_error() {
  log_message "ERROR" "$1"
  # Print errors to stderr regardless of verbose setting
  echo "❌ ERROR: $1" >&2
}

# Function to log a debug message (only when DEBUG=true)
# Usage: log_debug "Debug message here"
function log_debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    log_message "DEBUG" "$1"
    # Print debug messages to stdout if debug mode is enabled
    echo "🔍 DEBUG: $1"
  fi
}

# ======================================
# OS Detection and Compatibility
# ======================================

# Detect operating system
function detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  elif [[ "$(uname)" == "Linux" ]]; then
    echo "linux"
  else
    log_warning "Unsupported operating system: $(uname)"
    echo "unknown"
  fi
}

# Format month based on OS for better display
function format_month() {
  local month=$1  # Assumes YYYY-MM input format
  local os=$(detect_os)
  
  if [[ "$os" == "macos" ]]; then
    # Convert to DD-MM-YYYY format (first day of month)
    date -j -f "%Y-%m" "$month-01" "+%d-%m-%Y" 2>/dev/null || echo "$month"
  elif [[ "$os" == "linux" ]]; then
    date -d "$month-01" "+%d-%m-%Y" 2>/dev/null || echo "$month"
  else
    echo "$month"
  fi
}

# Format date based on OS
function format_date() {
  local date_str=$1
  local format=${2:-"+%d-%m-%Y"}
  local os=$(detect_os)
  
  if [[ -z "$date_str" ]]; then
    log_error "No date provided to format_date function"
    return 1
  fi
  
  if [[ "$os" == "macos" ]]; then
    # macOS date command (assumes date_str is in YYYY-MM-DD format)
    date -j -f "%d-%m-%Y" "$date_str" "$format" 2>/dev/null || echo "$date_str"
  elif [[ "$os" == "linux" ]]; then
    # Linux date command
    date -d "$date_str" "$format" 2>/dev/null || echo "$date_str"
  else
    # Fallback
    echo "$date_str"
  fi
}

# Check if a command exists
function command_exists() {
  command -v "$1" &> /dev/null
  return $?
}

# Get terminal width
function get_terminal_width() {
  local width=80 # Default fallback
  
  if command_exists tput; then
    width=$(tput cols)
  elif command_exists stty; then
    width=$(stty size 2>/dev/null | cut -d' ' -f2)
  fi
  
  echo $width
}

# Print a horizontal line
function print_line() {
  local width=${1:-$(get_terminal_width)}
  printf "%0.s-" $(seq 1 $width)
  echo ""
}

# Print centered text
function print_centered() {
  local text=$1
  local width=${2:-$(get_terminal_width)}
  local padding=$(( (width - ${#text}) / 2 ))
  
  if [[ $padding -lt 0 ]]; then
    padding=0
  fi
  
  printf "%${padding}s" ""
  echo "$text"
}

# Safely execute commands with error handling
function safe_exec() {
  local cmd=$1
  local error_msg=${2:-"Command failed: $cmd"}
  
  log_debug "Executing: $cmd"
  
  eval "$cmd"
  local exit_code=$?
  
  if [[ $exit_code -ne 0 ]]; then
    log_error "$error_msg (Exit code: $exit_code)"
    return $exit_code
  fi
  
  return 0
}

# Check for dependencies
function check_dependencies() {
  local required_commands=("$@")
  local missing_commands=()
  
  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_commands+=("$cmd")
    fi
  done
  
  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing_commands[*]}"
    return 1
  fi
  
  return 0
}

# Test system compatibility
function test_compatibility() {
  local os=$(detect_os)
  echo "Detecting system compatibility..."
  echo "Operating System: $os"
  
  # Check for required commands
  echo "Testing required commands:"
  
  local all_commands_available=true
  local required_commands=("grep" "sed" "less" "cat" "date")
  
  for cmd in "${required_commands[@]}"; do
    if command_exists "$cmd"; then
      echo "✅ $cmd: Available"
    else
      echo "❌ $cmd: Not found"
      all_commands_available=false
    fi
  done
  
  # Test date formatting
  echo "Testing date formatting..."
  local test_date="2023-01-15"
  local formatted_date=$(format_date "$test_date")
  echo "Sample date conversion: $test_date -> $formatted_date"
  
  # Test terminal width detection
  echo "Terminal width: $(get_terminal_width) columns"
  
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