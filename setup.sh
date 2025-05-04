#!/bin/zsh

# ===========================================
# Journash - Coding Journal CLI Setup Script
# ===========================================

# Constants
EXIT_SUCCESS=0
EXIT_FAILURE=1

# ANSI color codes
COLOR_RESET="\033[3;0m"
COLOR_RED="\033[1;31m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_GRAY="\033[1;30m"
COLOR_CYAN="\033[1;36m"
COLOR_WHITE="\033[3;37m"

# ===========================================
# Helper Functions
# ===========================================

# Display banner
function display_banner() {
  clear
  echo -e "${COLOR_RED}"
  echo "    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
  echo "    ┃                                                                           ┃"
  echo "    ┃       ██╗ ██████╗ ██╗   ██╗██████╗ ███╗   ██╗ █████╗ ███████╗ ██╗   ██╗   ┃"
  echo "    ┃       ██║██╔═══██╗██║   ██║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╚═══██║   ┃"
  echo "    ┃       ██║██║   ██║██║   ██║██████╔╝██╔██╗ ██║███████║███████╗ ████████║   ┃"
  echo "    ┃  ██   ██║██║   ██║██║   ██║██╔══██╗██║╚██╗██║██╔══██║╚════██║ ██╔═══██║   ┃"
  echo "    ┃  ╚█████╔╝╚██████╔╝╚██████╔╝██║  ██║██║ ╚████║██║  ██║███████║ ██║   ██║   ┃"
  echo "    ┃   ╚════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝ ╚═╝   ╚═╝   ┃"
  echo "    ┃                                                                           ┃"
  echo "    ┃                   Track your development process over time                ┃"
  echo "    ┃                                                                           ┃"
  echo "    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
  echo -e "${COLOR_RESET}"
  echo ""
}

# Display simple section header
function section_header() {
  local title="$1"
  echo ""
  echo -e "${COLOR_RED}==> ${COLOR_WHITE}${title}${COLOR_RESET}"
}

# Display progress with a single clock face that changes
function progress_bar() {
  local duration=3.0
  local steps=12
  local step_duration=$(echo "scale=4; $duration/$steps" | bc)
  local clocks=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛")
  local message="$1"
  
  # Print the message first
  echo -ne "${message} "
  
  for ((i=0; i<steps; i++)); do
    printf "\r${message} ${COLOR_WHITE}${clocks[$i]}${COLOR_RESET}"
    sleep $step_duration
  done
  
  # Complete with checkmark
  printf "\r${message} ${COLOR_GREEN}✓${COLOR_RESET}\n"
}

# Display error message and exit 
function handle_error() {
  local message="$1"
  local exit_code="${2:-$EXIT_FAILURE}"
  
  echo -e "${COLOR_RED}❌ ERROR: $message${COLOR_RESET}" >&2
  exit "$exit_code"
}

# Display warning message but continue execution
function show_warning() {
  local message="$1"
  echo -e "${COLOR_YELLOW}⚠️ WARNING: $message${COLOR_RESET}"
}

# Display success message
function show_success() {
  local message="$1"
  echo -e "${COLOR_GREEN}✅ $message${COLOR_RESET}"
}

# Execute command safely with error handling
function safe_execute() {
  local command="$1"
  local error_message="$2"
  local success_message="${3:-Command executed successfully}"
  
  echo -ne "${COLOR_CYAN}⏳ Executing: ${COLOR_RESET}"
  eval "$command" &
  local pid=$!
  wait $pid
  
  if [[ $? -ne 0 ]]; then
    handle_error "$error_message"
  else
    show_success "$success_message"
  fi
  
  return $EXIT_SUCCESS
}

# ===========================================
# Setup Script
# ===========================================

display_banner

echo ""
echo -e "${COLOR_WHITE}Setting up Journash - Coding Journal CLI...${COLOR_RESET}"
echo ""

# Define the main directory for the journal
JOURNAL_DIR="$HOME/.coding_journal"

section_header "Creating directory structure"

# Create main directory if it doesn't exist
if [[ ! -d "$JOURNAL_DIR" ]]; then
  echo -ne "${COLOR_WHITE}→ Creating main directory: $JOURNAL_DIR${COLOR_WHITE} "
  mkdir -p "$JOURNAL_DIR" &
  if [[ $? -ne 0 ]]; then
    handle_error "Failed to create journal directory: $JOURNAL_DIR"
  else
    show_success "${COLOR_WHITE}Main directory created successfully"
  fi
else
  echo -e "${COLOR_WHITE}→ Main directory already exists: $JOURNAL_DIR${COLOR_WHITE}"
fi

# Create subdirectories
for dir in "bin" "data" "config"; do
  if [[ ! -d "$JOURNAL_DIR/$dir" ]]; then
    echo -ne "${COLOR_WHITE}→ Creating directory: $JOURNAL_DIR/$dir${COLOR_RESET} "
    mkdir -p "$JOURNAL_DIR/$dir" &
    if [[ $? -ne 0 ]]; then
      handle_error "Failed to create directory: $JOURNAL_DIR/$dir"
    else
      show_success "${COLOR_WHITE}$dir directory created${COLOR_RESET}"
    fi
  else
    echo -e "${COLOR_WHITE}→ Directory already exists: $JOURNAL_DIR/$dir${COLOR_RESET}"
  fi
done

section_header "Configuring default settings"

# Create default settings.conf if it doesn't exist
SETTINGS_FILE="$JOURNAL_DIR/config/settings.conf"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo -e "${COLOR_WHITE}→ Creating default settings file: $SETTINGS_FILE${COLOR_RESET}"
  
  # Add clock animation
  progress_bar "  Generating configuration..."
  
  cat > "$SETTINGS_FILE" << EOF
# Journash Configuration File

# IDE Settings
IDE_COMMAND="cursor"        # Command to open the IDE
IDE_ARGS="--wait"           # Arguments for the IDE command
TERMINAL_EMULATOR="iterm"   # Terminal emulator

# Error Handling Settings
LOG_LEVEL=0                 # 0=INFO, 1=WARNING, 2=ERROR, 3=FATAL
LOG_FILE="$JOURNAL_DIR/journash.log"

# Journal Settings
AUTO_JOURNAL_ENABLED=true           # Enable/disable auto-journaling after IDE closes
JOURNAL_FILE_FORMAT="%d-%m-%Y.md"   # Date format for journal files

# Terminal Settings
TERMINAL_WIDTH=80                   # Default terminal width for formatting

# Appearance
PROMPT_SYMBOL="📝"                  # Symbol to use in journal prompts
EOF
  
  if [[ $? -ne 0 ]]; then
    handle_error "Failed to create settings file: $SETTINGS_FILE"
  fi
  
  show_success "Default settings configured"
  
else
  echo -e "${COLOR_WHITE}→ Settings file already exists: $SETTINGS_FILE${COLOR_RESET}"
fi

section_header "Installing script components"

# Copy main script files to bin directory
SCRIPT_FILES=(
  "journal_main.sh"
  "journal_utils.sh"
  "journal_git.sh"
  "journal_entry.sh"
  "journal_view.sh" 
  "journal_search.sh"
  "journal_stats.sh"
  "zsh_integration.sh"
)

echo -e "${COLOR_WHITE}→  Installing script components:${COLOR_RESET}"

# Add a clock animation for script installation
progress_bar "📜 Preparing script environment..."

for script in "${SCRIPT_FILES[@]}"; do
  SRC_SCRIPT="./src/bin/$script"
  DEST_SCRIPT="$JOURNAL_DIR/bin/$script"
  
  if [[ -f "$SRC_SCRIPT" ]]; then
    echo -ne "  ${COLOR_WHITE}$script${COLOR_RESET} "
    cp "$SRC_SCRIPT" "$DEST_SCRIPT" &>/dev/null
    chmod +x "$DEST_SCRIPT" &>/dev/null
    
    if [[ $? -ne 0 ]]; then
      echo -e "${COLOR_RED}❌${COLOR_RESET}"
      show_warning "Failed to copy script: $SRC_SCRIPT"
    else
      echo -e "${COLOR_GREEN}✓${COLOR_RESET}"
    fi
  else
    echo -e "  ${COLOR_WHITE}$script${COLOR_RESET} ${COLOR_YELLOW}⚠️  Not found${COLOR_RESET}"
    show_warning "Script not found at $SRC_SCRIPT. Please create the script file first."
  fi
done

section_header "Configuring shell integration"

# Check if Zsh integration already exists
if ! grep -q "# Journash Integration" "$HOME/.zshrc"; then
  echo -e "${COLOR_WHITE}→  Setting up Zsh integration...${COLOR_RESET}"
  
  progress_bar "👤 Adding aliases and functions to .zshrc..."
  
  # Call the dedicated zsh integration script
  "$JOURNAL_DIR/bin/zsh_integration.sh" &>/dev/null
  
  if [[ $? -ne 0 ]]; then
    echo -e "${COLOR_RED}Failed${COLOR_RESET}"
    show_warning "Failed to set up Zsh integration"
  else
    show_success "Shell integration complete"
  fi
else
  echo -e "${COLOR_WHITE}→ Journash integration already exists in ~/.zshrc${COLOR_RESET}"
fi

section_header "System compatibility check"

# Test system compatibility
echo -e "${COLOR_WHITE}→  Testing system compatibility...${COLOR_RESET}"
if [[ -f "$JOURNAL_DIR/bin/journal_utils.sh" ]]; then

  progress_bar "🛠️  Running system diagnostics..."
  
  "$JOURNAL_DIR/bin/journal_utils.sh"
  if [[ $? -ne 0 ]]; then
    show_warning "System compatibility check failed. Some features may not work correctly."
  else
    show_success "System compatibility check passed"
  fi
else
  show_warning "Utility script not found. Cannot test system compatibility."
fi

section_header "Dependency check"

# Check for required utilities
echo -e "${COLOR_WHITE}→  Checking for required dependencies...${COLOR_RESET}"

# Check for Git (required for version control)
progress_bar "🗄️  Checking for Git..."

if ! command -v git &> /dev/null; then
  echo -e "${COLOR_YELLOW}⚠️  Git is not installed. Version control features will not be available.${COLOR_RESET}"
  echo -e "  ${COLOR_GRAY}ℹ️  Please install Git to use backup and versioning features.${COLOR_RESET}"
else
  show_success "Git is available. Version control features can be used."
fi

section_header "Optional configuration"

# Feature setup questions
echo -e "${COLOR_WHITE}→  Would you like to set up Git for version control of your journal? (y/n)${COLOR_RESET}"
read setup_git

if [[ "$setup_git" == "y" || "$setup_git" == "Y" ]]; then
  # Check if Git is available
  if command -v git &> /dev/null; then
    progress_bar "🧾 Initializing Git repository..."
    
    if ! "$JOURNAL_DIR/bin/journal_git.sh" init &>/dev/null; then
      show_warning "Failed to initialize Git repository. You can run 'journash git init' later."
    else
      show_success "Git repository initialized"
      
      echo -e "${COLOR_WHITE}→ Would you like to set up a remote repository for backup? (y/n)${COLOR_RESET}"
      read setup_remote
      
      if [[ "$setup_remote" == "y" || "$setup_remote" == "Y" ]]; then
        echo -e "${COLOR_WHITE}→  Please enter the URL of your remote repository:${COLOR_RESET}"
        read remote_url
        
        if [[ -n "$remote_url" ]]; then
          progress_bar "📡 Setting up remote repository..."
          
          if ! "$JOURNAL_DIR/bin/journal_git.sh" remote "$remote_url" &>/dev/null; then
            show_warning "Failed to set up remote repository. You can run 'journash git remote $remote_url' later."
          else
            show_success "Remote repository configured"
          fi
        fi
      fi
    fi
  else
    show_warning "Cannot set up Git repository: Git is not installed."
    echo -e "${COLOR_GRAY}ℹ️  Please install Git and run 'journash git init' later.${COLOR_RESET}"
  fi
fi

section_header "Setup complete"


echo -e "${COLOR_RED}"
echo "    ╔══════════════════════════════════════════════╗"
echo -e "    ║   ${COLOR_WHITE}✨  \033[1mJOURNASH SUCCESSFULLY INSTALLED\033[0m${COLOR_RED}  ✨    ║"
echo "    ╚══════════════════════════════════════════════╝"
echo -e "${COLOR_RESET}"


echo -e "${COLOR_YELLOW}    ┌───────────────────────────────────────────────────────────┐${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    │${COLOR_RESET}                 ${COLOR_WHITE}\033[1mCOMMAND REFERENCE\033[0m${COLOR_RESET}                    ${COLOR_YELLOW}     │${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    ├───────────────────────────────────────────────────────────┤${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    │${COLOR_RESET}  ${COLOR_WHITE}\033[1mjournash\033[0m${COLOR_RESET}                 - Create a coding journal entry ${COLOR_YELLOW}│${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    │${COLOR_RESET}  ${COLOR_WHITE}\033[1mjournash view\033[0m${COLOR_RESET}            - View your journal entries     ${COLOR_YELLOW}│${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    │${COLOR_RESET}  ${COLOR_WHITE}\033[1mjournash search \"term\"\033[0m${COLOR_RESET}   - Search through your entries   ${COLOR_YELLOW}│${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    │${COLOR_RESET}  ${COLOR_WHITE}\033[1mjournash stats\033[0m${COLOR_RESET}           - Show journal statistics       ${COLOR_YELLOW}│${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    │${COLOR_RESET}  ${COLOR_WHITE}\033[1mjournash git\033[0m${COLOR_RESET}             - Manage git repository         ${COLOR_YELLOW}│${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    │${COLOR_RESET}  ${COLOR_WHITE}\033[1mjournash help\033[0m${COLOR_RESET}            - View available commands       ${COLOR_YELLOW}│${COLOR_RESET}"
echo -e "${COLOR_YELLOW}    └───────────────────────────────────────────────────────────┘${COLOR_RESET}"
echo ""


echo -e "${COLOR_GREEN}    ┌───────────────────────────────────────────────────────────┐${COLOR_RESET}"
echo -e "${COLOR_GREEN}    │${COLOR_RESET}                    ${COLOR_YELLOW}\033[1m💡 PRO TIP\033[0m${COLOR_RESET}                         ${COLOR_GREEN}    │${COLOR_RESET}"
echo -e "${COLOR_GREEN}    ├───────────────────────────────────────────────────────────┤${COLOR_RESET}"
echo -e "${COLOR_GREEN}    │${COLOR_RESET}  For automatic journaling when closing your IDE:          ${COLOR_GREEN}│${COLOR_RESET}"
echo -e "${COLOR_GREEN}    │${COLOR_RESET}                                                           ${COLOR_GREEN}│${COLOR_RESET}"
echo -e "${COLOR_GREEN}    │${COLOR_RESET}  Use ${COLOR_WHITE}\033[1mcode_journal\033[0m${COLOR_RESET} instead of your normal IDE command      ${COLOR_GREEN}│${COLOR_RESET}"
echo -e "${COLOR_GREEN}    │${COLOR_RESET}  Example: ${COLOR_WHITE}\033[1mcode_journal ~/projects/my-project\033[0m${COLOR_RESET}            ${COLOR_GREEN}  │${COLOR_RESET}"
echo -e "${COLOR_GREEN}    └───────────────────────────────────────────────────────────┘${COLOR_RESET}"
echo ""

echo ""
echo -e "    ${COLOR_WHITE}Restart your terminal or run 'source ~/.zshrc' to begin${COLOR_RESET}"
echo ""

exit $EXIT_SUCCESS