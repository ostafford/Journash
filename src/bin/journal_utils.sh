#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI
# Utility functions for cross-platform compatibility and logging
# ===========================================

# Constants
EXIT_SUCCESS=0
EXIT_FAILURE=1

# ===========================================
# Configuration variables
# ===========================================
JOURNAL_DIR="$HOME/.coding_journal"
LOG_FILE="$JOURNAL_DIR/journash.log"

# ===========================================
# Logging functions
# ===========================================

# Log messages with timestamp to file and optionally to console
# Usage: log_message <level> <message>
# Parameters:
#   level - Log level (INFO, WARNING, ERROR, DEBUG)
#   message - Message to log
# Returns: 0 on success, 1 on failure
function log_message() {
  local level=$1
  local message=$2
  local timestamp=$(date +"%d-%m-%Y %H:%M:%S")
  
  # Create log directory if it doesn't exist
  if [[ ! -d "$(dirname "$LOG_FILE")" ]]; then
    mkdir -p "$(dirname "$LOG_FILE")" || return $EXIT_FAILURE
  fi
  
  # Append log message to log file
  echo "[$timestamp] [$level] $message" >> "$LOG_FILE" || return $EXIT_FAILURE
  
  # Print to stdout if verbose mode is enabled
  if [[ "${VERBOSE_LOGGING:-false}" == "true" ]]; then
    echo "[$level] $message"
  fi
  
  return $EXIT_SUCCESS
}

# Log informational messages
# Usage: log_info <message>
# Parameters:
#   message - Information message to log
# Returns: Result of log_message call
function log_info() {
  log_message "INFO" "$1"
  return $?
}

# Log warning messages and print to console
# Usage: log_warning <message>
# Parameters:
#   message - Warning message to log
# Returns: Result of log_message call
function log_warning() {
  log_message "WARNING" "$1"
  # Print warnings to stdout regardless of verbose setting
  echo "⚠️ WARNING: $1"
  return $?
}

# Log error messages and print to stderr
# Usage: log_error <message>
# Parameters:
#   message - Error message to log
# Returns: Result of log_message call
function log_error() {
  log_message "ERROR" "$1"
  # Print errors to stderr regardless of verbose setting
  echo "❌ ERROR: $1" >&2
  return $?
}

# Log debug messages when debug mode is enabled
# Usage: log_debug <message>
# Parameters:
#   message - Debug message to log
# Returns: Result of log_message call or 0 if debug disabled
function log_debug() {
  if [[ "${DEBUG:-false}" == "true" ]]; then
    log_message "DEBUG" "$1"
    # Print debug messages to stdout if debug mode is enabled
    echo "🔍 DEBUG: $1"
    return $?
  fi
  return $EXIT_SUCCESS
}

# Handle fatal errors - log, display, and exit
# Usage: handle_error <message> [exit_code]
# Parameters:
#   message - Error message to display
#   exit_code - Optional exit code, defaults to 1
function handle_error() {
  local message="$1"
  local exit_code="${2:-$EXIT_FAILURE}"
  
  log_error "$message"
  exit "$exit_code"
}

# ===========================================
# OS Detection and Compatibility
# ===========================================

# Detect the current operating system
# Usage: detect_os
# Returns: String indicating OS type (macos, linux, or unknown)
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

# Format month string for display
# Usage: format_month <month_string>
# Parameters:
#   month_string - Month in DD-MM-YYYY or YYYY-MM format
# Returns: Formatted month string
function format_month() {
  local month=$1
  
  # If it's already in DD-MM-YYYY format, no need to convert
  if [[ "$month" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
    echo "$month"
    return $EXIT_SUCCESS
  fi
  
  # If it's in YYYY-MM format, create a nicer display format
  if [[ "$month" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    # Extract year and month
    local year=${month:0:4}
    local month_num=${month:5:2}
    
    # Convert month number to name using arrays
    local month_names=("" "January" "February" "March" "April" "May" "June" 
                      "July" "August" "September" "October" "November" "December")
    local month_name=${month_names[${month_num#0}]}
    
    echo "01-${month_num}-${year} (${month_name} ${year})"
    return $EXIT_SUCCESS
  fi
  
  # If format not recognized, return as is
  echo "$month"
  return $EXIT_SUCCESS
}

# Format date based on operating system
# Usage: format_date <date_string> [format]
# Parameters:
#   date_string - Date in DD-MM-YYYY format
#   format - Optional format string (default: +%d-%m-%Y)
# Returns: Formatted date or original string if conversion fails
function format_date() {
  local date_str=$1
  local format=${2:-"+%d-%m-%Y"}
  local os=$(detect_os)
  
  if [[ -z "$date_str" ]]; then
    log_error "No date provided to format_date function"
    return $EXIT_FAILURE
  fi
  
  if [[ "$os" == "macos" ]]; then
    # macOS date command (assumes date_str is in DD-MM-YYYY format)
    date -j -f "%d-%m-%Y" "$date_str" "$format" 2>/dev/null || echo "$date_str"
  elif [[ "$os" == "linux" ]]; then
    # Linux date command
    date -d "$date_str" "$format" 2>/dev/null || echo "$date_str"
  else
    # Fallback
    echo "$date_str"
  fi
}

# ===========================================
# System Utility Functions
# ===========================================

# Check if a command exists
# Usage: command_exists <command>
# Parameters:
#   command - Command to check
# Returns: 0 if command exists, 1 if not
function command_exists() {
  command -v "$1" &> /dev/null
  return $?
}

# Get current terminal width
# Usage: get_terminal_width
# Returns: Width of terminal in columns (default: 80)
function get_terminal_width() {
  local width=${TERMINAL_WIDTH:-80} # Use configured width or default
  
  if command_exists tput; then
    width=$(tput cols)
  elif command_exists stty; then
    width=$(stty size 2>/dev/null | cut -d' ' -f2)
  fi
  
  echo $width
}

# Print a horizontal line
# Usage: print_line [width]
# Parameters:
#   width - Optional width (default: terminal width)
function print_line() {
  local width=${1:-$(get_terminal_width)}
  printf "%0.s-" $(seq 1 $width)
  echo ""
}

# Print centered text
# Usage: print_centered <text> [width]
# Parameters:
#   text - Text to center
#   width - Optional width (default: terminal width)
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
# Usage: safe_exec <command> [error_message]
# Parameters:
#   command - Command to execute
#   error_message - Optional custom error message
# Returns: Command's exit code or 1 on failure
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
  
  return $EXIT_SUCCESS
}

# Check for required dependencies
# Usage: check_dependencies <command1> [command2...]
# Parameters:
#   command* - List of commands to check
# Returns: 0 if all dependencies available, 1 if missing
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
    return $EXIT_FAILURE
  fi
  
  return $EXIT_SUCCESS
}

# ===========================================
# System compatibility testing
# ===========================================

# Test system compatibility for Journash
# Usage: test_compatibility
# Returns: 0 if system is compatible, 1 if not
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
  local test_date="15-01-2025"
  local formatted_date=$(format_date "$test_date")
  echo "Sample date conversion: $test_date -> $formatted_date"
  
  # Test terminal width detection
  echo "Terminal width: $(get_terminal_width) columns"
  
  if [[ "$all_commands_available" == true ]]; then
    echo "✅ All required commands are available"
    return $EXIT_SUCCESS
  else
    echo "❌ Some required commands are missing"
    return $EXIT_FAILURE
  fi
}

# ===========================================
# Main execution (when run directly)
# ===========================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  test_compatibility
  exit $?
fi