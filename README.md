# Journash

> A terminal-based journaling system designed for developers to track their coding journey.

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Shell](https://img.shields.io/badge/shell-zsh-green.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20|%20Linux-lightgrey.svg)

## 📋 Overview

Journash is a seamless CLI journaling system that:

- Automatically prompts for journal entries when closing your IDE
- Allows manual journal entries through simple terminal commands
- Differentiates between coding and personal journal entries
- Organizes entries by date in an easily navigable structure
- Integrates with Git for version control and backup

## 🚀 Features

### Journal Types

- **Coding Journal**: Triggered manually or automatically after IDE closure
  - Session duration
  - Work description
  - Challenges faced
  - Solutions discovered
  - Things learned
  - Next steps

- **Personal Journal**: For non-coding reflections
  - Gratitude reflection
  - Accomplishments
  - General thoughts

### Git Integration

- Automatic commit of journal entries
- Remote repository support for cloud backup
- Full version control of your journal

## 🛠️ Installation

```bash
# Clone the repository
git clone https://github.com/ostafford/journash.git
cd journash

# Run the setup script
./setup.sh
```

The setup script will:
1. Create necessary directories in `~/.coding_journal/`
2. Configure initial settings
3. Integrate with your zsh environment
4. Set up optional features like Git integration

## 📝 Usage

### Basic Commands

```bash
# Create a personal journal entry
journash

# Create a coding journal entry
journash code

# View available journals
journash view

# View entries for a specific month
journash view 2025-04

# Search entries for a specific term
journash search "python"

# Show journal statistics
journash stats
```

### Automatic Journaling

```bash
# Launch your IDE with auto-journaling on close
code_journal your_project/
```

When your IDE closes, a new terminal window will open to create a coding journal entry.

### Git Integration

```bash
# Initialize git repository for your journal
journash git init

# Set up remote repository
journash git remote https://github.com/yourusername/journal-backup.git

# Manually commit changes
journash git commit

# Push changes to remote
journash git push

# Check status
journash git status
```

## 📂 Project Structure

```
$HOME/
└── .coding_journal/
    ├── bin/                      # Scripts directory
    │   ├── journal_main.sh       # Main script with core functions
    │   ├── journal_utils.sh      # Utility functions
    │   └── journal_git.sh        # Git integration
    │
    ├── data/                     # Data directory
    │   └── YYYY-MM.md            # Journal entries by month
    │
    └── config/                   # Configuration directory
        ├── settings.conf         # User settings
        └── git.conf              # Git configuration
```

## ⚙️ Configuration

User preferences can be modified in the following files:

- `~/.coding_journal/config/settings.conf` - General settings
- `~/.coding_journal/config/git.conf` - Git integration settings

## 🔄 Cross-Platform Compatibility

Journash is designed to work on:
- macOS (primary platform)
- Linux (secondary platform) [Still in testing]

The utility functions automatically detect your OS and adjust commands accordingly. **(Still working on it with Fedora)**

## 🤝 Contributing

This project welcomes contributions and suggestions. Feel free to fork the repository and submit pull requests.

## 📄 License

[MIT License](LICENSE)

## 🙏 Acknowledgements

- Inspired by the practice of keeping coding journals
- Built with zsh scripts for cross-platform compatibility
- Git for version control
