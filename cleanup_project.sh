#!/bin/bash

echo "Starting complete project cleanup..."

# Check if the app has been uninstalled
if [ -f "/Applications/iConvert.app" ]; then
    echo "WARNING: iConvert app still exists in Applications folder."
    echo "Please run uninstall_iconvert.sh first."
    exit 1
fi

# Ask for confirmation
echo "This will delete ALL project files in the current directory."
echo "This includes source code, Xcode project files, and all other files."
read -p "Are you sure you want to proceed? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Cleanup aborted."
    exit 0
fi

# Remove all project files
echo "Removing all project files..."

# Remove Xcode project
rm -rf iConvert.xcodeproj

# Remove source code directories
rm -rf "iConvert"
rm -rf "iConvert Finder Extension"

# Remove scripts
rm -f reset_extension.sh
rm -f reload_extension.sh
rm -f check_webp_tools.sh
rm -f add_files.rb
rm -f uninstall_iconvert.sh

# Remove documentation
rm -f README.md
rm -f LICENSE
rm -rf README_assets
rm -f icon_256x256@2x.png
rm -f icon_256x256@2x_converted.jpg

# Remove git repository
rm -rf .git
rm -f .gitignore

# Remove macOS metadata
rm -f .DS_Store

echo "Project cleanup complete. All project files have been removed."
echo "This script will now delete itself."

# Create a self-destruct command
rm -f "$0"