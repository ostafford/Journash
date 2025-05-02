# Journash

> A terminal-based journaling system designed for developers to track their coding journey.

![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)
![Shell](https://img.shields.io/badge/shell-zsh-green.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20|%20Linux-lightgrey.svg)

## 📋 Overview

Journash is a seamless CLI journaling system that documents your coding journey:

- Automatically prompts for journal entries when closing your IDE
- Creates structured entries with predefined fields to track progress
- Organizes entries by date in an easily navigable structure
- Integrates with Git for version control and backup

Perfect for tracking your progress through software development projects, bootcamps, or capstone projects.

## 🚀 Features

### Coding Journal Tracking

Journash captures key information about your coding sessions:

- Session duration
- Work description
- Challenges faced
- Solutions discovered
- Things learned
- Next steps

These structured entries help you build a comprehensive record of your development journey and learning process.

### Automatic Journal Entries

The system integrates with your workflow by automatically triggering a journal prompt when you close your IDE:

1. Launch your IDE with the `code_journal` command
2. Code as usual
3. When you close the IDE, a terminal window appears prompting for a journal entry
4. Complete the questions to document your session

### Git Integration

Built-in Git support ensures your journal is safely stored and versioned:

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
2. Configure initial settings based on your system
3. Integrate with your zsh environment
4. Set up optional Git integration

## 📝 Usage

### Basic Commands

```bash
# Create a coding journal entry
journash

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

## ⚙️ Configuration

User preferences can be modified in the following files:

- `~/.coding_journal/config/settings.conf` - General settings and IDE preferences
- `~/.coding_journal/config/git.conf` - Git integration settings

Main settings you can configure:

```bash
# IDE Settings
IDE_COMMAND="cursor"        # Command to open your IDE (vscode, cursor, etc.)
IDE_ARGS="--wait"           # Arguments for the IDE command
TERMINAL_EMULATOR="iterm"   # Your terminal (iterm, gnome-terminal, etc.)

# Journal Settings  
AUTO_JOURNAL_ENABLED=true   # Enable/disable auto-journaling
JOURNAL_FILE_FORMAT="%Y-%m.md"  # Date format for journal files
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

## 🔄 Cross-Platform Compatibility

Journash is designed to work on:
- macOS (primary platform)
- Linux (secondary platform)

The utility functions automatically detect your OS and adjust commands accordingly.

## 💡 Troubleshooting

### Common Issues

1. **IDE doesn't trigger journal entry on close**
   - Check your terminal emulator setting in `settings.conf`
   - Ensure you're using `code_journal` instead of your normal IDE command
   - Try running with `DEBUG=true code_journal` to see debugging output

2. **Git integration not working**
   - Check if Git is installed: `which git`
   - Verify `GIT_ENABLED=true` in git.conf
   - Run `journash git status` to check repository status

3. **Cross-platform issues**
   - For Linux, ensure you're using a supported terminal emulator
   - Run `journash test` to check system compatibility

## 🤝 Contributing

This project welcomes contributions and suggestions. Feel free to fork the repository and submit pull requests.

## 📄 License

[MIT License](LICENSE)

## 🙏 Acknowledgements

- Inspired by the practice of keeping coding journals
- Built with zsh scripts for cross-platform compatibility
- Git for version control