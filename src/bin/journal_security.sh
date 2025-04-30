#!/bin/zsh

# Journash - Coding Journal CLI
# Security and encryption functions

# Configuration variables
JOURNAL_DIR="$HOME/.coding_journal"
CONFIG_DIR="$JOURNAL_DIR/config"
DATA_DIR="$JOURNAL_DIR/data"
BIN_DIR="$JOURNAL_DIR/bin"
SETTINGS_FILE="$CONFIG_DIR/settings.conf"
SECURITY_FILE="$CONFIG_DIR/security.conf"
UTILS_SCRIPT="$BIN_DIR/journal_utils.sh"

# Source utility functions if available
if [[ -f "$UTILS_SCRIPT" ]]; then
  source "$UTILS_SCRIPT"
else
  echo "Warning: Utility script not found at $UTILS_SCRIPT"
  # Fallback for critical functions
  function print_line() { echo "----------------------"; }
fi

# Source settings and security configuration
if [[ -f "$SETTINGS_FILE" ]]; then
  source "$SETTINGS_FILE"
else
  echo "Error: Settings file not found. Please run setup script first."
  exit 1
fi

if [[ -f "$SECURITY_FILE" ]]; then
  source "$SECURITY_FILE"
else
  echo "Error: Security configuration not found. Please run setup script first."
  exit 1
fi

# Function to check if encryption is available
function check_encryption_available() {
  if ! command -v openssl &> /dev/null; then
    echo "❌ OpenSSL is not installed. Encryption is not available."
    return 1
  fi
  
  return 0
}

# Function to generate a secure hash from a password
function hash_password() {
  local password=$1
  
  # Generate salt
  local salt=$(openssl rand -hex 8)
  
  # Hash password with salt using SHA-256
  local hash=$(echo -n "${password}${salt}" | openssl dgst -sha256 | sed 's/^.* //')
  
  # Return salt and hash
  echo "$salt:$hash"
}

# Function to verify a password against stored hash
function verify_password() {
  local password=$1
  local stored_hash=$2
  
  # Extract salt and hash
  local salt=$(echo "$stored_hash" | cut -d: -f1)
  local hash=$(echo "$stored_hash" | cut -d: -f2)
  
  # Hash the provided password with the stored salt
  local check_hash=$(echo -n "${password}${salt}" | openssl dgst -sha256 | sed 's/^.* //')
  
  # Compare hashes
  if [[ "$check_hash" == "$hash" ]]; then
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Function to set up encryption password
function setup_encryption() {
  if ! check_encryption_available; then
    return 1
  fi
  
  echo "🔒 Setting up encryption for private journal entries"
  print_line
  
  # Ask for password
  echo "Please enter a password to use for encrypting private entries:"
  read -s password
  echo "Please confirm your password:"
  read -s password_confirm
  
  if [[ "$password" != "$password_confirm" ]]; then
    echo "❌ Passwords do not match. Please try again."
    return 1
  fi
  
  if [[ -z "$password" ]]; then
    echo "❌ Password cannot be empty. Please try again."
    return 1
  fi
  
  # Hash the password
  local password_hash=$(hash_password "$password")
  
  # Update security.conf
  sed -i.bak 's/^ENCRYPTION_ENABLED=.*/ENCRYPTION_ENABLED=true/' "$SECURITY_FILE"
  sed -i.bak 's/^# PASSWORD_HASH=.*/PASSWORD_HASH='"$password_hash"'/' "$SECURITY_FILE"
  
  echo "✅ Encryption set up successfully!"
  echo "You can now mark journal entries as private."
}

# Function to encrypt a string
function encrypt_text() {
  local text=$1
  local password=$2
  
  # Encrypt using OpenSSL (AES-256-CBC)
  echo "$text" | openssl enc -aes-256-cbc -a -salt -pass pass:"$password" 2>/dev/null
}

# Function to decrypt a string
function decrypt_text() {
  local encrypted=$1
  local password=$2
  
  # Decrypt using OpenSSL (AES-256-CBC)
  echo "$encrypted" | openssl enc -aes-256-cbc -a -d -salt -pass pass:"$password" 2>/dev/null
}

# Function to prompt for password and verify
function prompt_for_password() {
  if [[ "$ENCRYPTION_ENABLED" != "true" || -z "$PASSWORD_HASH" ]]; then
    echo "❌ Encryption is not set up. Please run 'journash security setup' first."
    return 1
  fi
  
  echo "Please enter your encryption password:"
  read -s password
  
  if verify_password "$password" "$PASSWORD_HASH"; then
    echo "$password"
    return 0
  else
    echo "❌ Incorrect password."
    return 1
  fi
}

# Function to encrypt a journal entry
function encrypt_entry() {
  local entry_text=$1
  
  # Check if encryption is enabled
  if [[ "$ENCRYPTION_ENABLED" != "true" || -z "$PASSWORD_HASH" ]]; then
    echo "❌ Encryption is not set up. Please run 'journash security setup' first."
    return 1
  fi
  
  # Get password
  local password=$(prompt_for_password)
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  
  # Encrypt the entry
  local encrypted=$(encrypt_text "$entry_text" "$password")
  
  # Add encryption marker
  echo "<!-- ENCRYPTED ENTRY -->"
  echo "$encrypted"
}

# Function to decrypt a journal entry
function decrypt_entry() {
  local encrypted_text=$1
  
  # Check if encryption is enabled
  if [[ "$ENCRYPTION_ENABLED" != "true" || -z "$PASSWORD_HASH" ]]; then
    echo "❌ Encryption is not set up. Please run 'journash security setup' first."
    return 1
  fi
  
  # Get password
  local password=$(prompt_for_password)
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  
  # Remove encryption marker if present
  encrypted_text=$(echo "$encrypted_text" | sed 's/<!-- ENCRYPTED ENTRY -->//')
  
  # Decrypt the entry
  local decrypted=$(decrypt_text "$encrypted_text" "$password")
  
  echo "$decrypted"
}

# Function to change password
function change_password() {
  if [[ "$ENCRYPTION_ENABLED" != "true" || -z "$PASSWORD_HASH" ]]; then
    echo "❌ Encryption is not set up. Please run 'journash security setup' first."
    return 1
  fi
  
  echo "🔑 Changing encryption password"
  print_line
  
  echo "Please enter your current password:"
  read -s current_password
  
  if ! verify_password "$current_password" "$PASSWORD_HASH"; then
    echo "❌ Incorrect password."
    return 1
  fi
  
  echo "Please enter your new password:"
  read -s new_password
  echo "Please confirm your new password:"
  read -s new_password_confirm
  
  if [[ "$new_password" != "$new_password_confirm" ]]; then
    echo "❌ Passwords do not match. Please try again."
    return 1
  fi
  
  if [[ -z "$new_password" ]]; then
    echo "❌ Password cannot be empty. Please try again."
    return 1
  fi
  
  # Hash the new password
  local new_password_hash=$(hash_password "$new_password")
  
  # Update security.conf with new hash
  sed -i.bak 's/^PASSWORD_HASH=.*/PASSWORD_HASH='"$new_password_hash"'/' "$SECURITY_FILE"
  
  echo "✅ Password changed successfully!"
  
  # TODO: Re-encrypt existing encrypted entries with new password
  echo "Note: Existing encrypted entries will still use the old password."
  echo "Consider re-encrypting them with the new password."
}

# Process command line arguments
if [[ $# -eq 0 || "$1" == "help" ]]; then
  # Display help information
  echo "Usage: journash security [COMMAND]"
  echo "Manage security and encryption for journal entries."
  echo ""
  echo "Commands:"
  echo "  setup            Set up encryption with a password"
  echo "  encrypt TEXT     Encrypt a piece of text"
  echo "  decrypt TEXT     Decrypt an encrypted text"
  echo "  password         Change your encryption password"
  echo "  status           Check encryption status"
  echo "  help             Show this help message"
  echo ""
  echo "Examples:"
  echo "  journash security setup      # Set up encryption"
  echo "  journash security status     # Check encryption status"
elif [[ "$1" == "setup" ]]; then
  setup_encryption
elif [[ "$1" == "encrypt" && -n "$2" ]]; then
  encrypt_entry "$2"
elif [[ "$1" == "decrypt" && -n "$2" ]]; then
  decrypt_entry "$2"
elif [[ "$1" == "password" ]]; then
  change_password
elif [[ "$1" == "status" ]]; then
  echo "Encryption status:"
  if [[ "$ENCRYPTION_ENABLED" == "true" ]]; then
    echo "✅ Encryption is enabled"
    if [[ -n "$PASSWORD_HASH" ]]; then
      echo "✅ Password is set up"
    else
      echo "❌ Password is not set up"
    fi
  else
    echo "❌ Encryption is disabled"
  fi
  
  # Check if openssl is available
  if check_encryption_available; then
    echo "✅ OpenSSL is available for encryption"
  fi
else
  echo "Unknown command: $1"
  echo "Try 'journash security help' for more information."
  exit 1
fi