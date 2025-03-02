#!/bin/bash

echo "===== COMPLETE ICONVERT UNINSTALLATION ====="
echo "This script will completely remove iConvert from your system."

# Kill any running iConvert processes
echo "Terminating any running iConvert processes..."
pkill -f "iConvert.app" || true
sleep 1

# Check if processes are still running and force kill if necessary
if pgrep -f "iConvert.app" > /dev/null; then
    echo "Some processes are still running. Attempting force kill..."
    pkill -9 -f "iConvert.app" || true
    sleep 1

    # If still running, show the processes and ask user what to do
    if pgrep -f "iConvert.app" > /dev/null; then
        echo "WARNING: Some iConvert processes are still running:"
        ps aux | grep -i "iConvert.app" | grep -v grep

        read -p "Do you want to continue anyway? (y/n): " continue_confirm
        if [ "$continue_confirm" != "y" ]; then
            echo "Uninstallation aborted."
            exit 1
        fi
        echo "Continuing with uninstallation despite running processes..."
    fi
fi

# Extension bundle ID
EXTENSION_ID="at.untitledapps.iconvert.iconvert-Finder-Extension"

# Unload the extension
echo "Unloading Finder extension..."
pluginkit -e ignore -i $EXTENSION_ID

# Kill Finder to force it to reload
echo "Restarting Finder..."
killall Finder

# Wait for Finder to restart
sleep 2

# Remove the app from Applications folder
echo "Removing iConvert application..."
sudo rm -rf "/Applications/iConvert.app" 2>/dev/null

# Remove the app from the current directory if it exists
echo "Checking for local app build..."
rm -rf "./iConvert.app" 2>/dev/null
rm -rf "./Build/Products/Release/iConvert.app" 2>/dev/null
rm -rf "./Build/Products/Debug/iConvert.app" 2>/dev/null

# Remove any cached extension data
echo "Removing app and extension cache data..."
rm -rf ~/Library/Caches/at.untitledapps.iconvert* 2>/dev/null
rm -rf ~/Library/Containers/at.untitledapps.iconvert* 2>/dev/null
rm -rf ~/Library/Group\ Containers/at.untitledapps.iconvert* 2>/dev/null
rm -rf ~/Library/Application\ Support/at.untitledapps.iconvert* 2>/dev/null

# Remove preferences
echo "Removing preferences..."
defaults delete at.untitledapps.iconvert 2>/dev/null

# Remove from Launch Services database
echo "Removing app from Launch Services database..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "/Applications/iConvert.app" 2>/dev/null

# Remove derived data
echo "Removing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/iConvert-* 2>/dev/null

# Verify extension is gone
echo "Verifying extension removal..."
if pluginkit -m | grep -i "iconvert"; then
    echo "WARNING: Extension still appears to be registered. You may need to restart your computer to completely remove it."
else
    echo "Extension successfully removed."
fi

echo "App uninstallation complete."

# Ask if user wants to remove project files
read -p "Do you want to remove all project files as well? (y/n): " cleanup_confirm

if [ "$cleanup_confirm" = "y" ]; then
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
    rm -f cleanup_project.sh

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
else
    echo "Project files were not removed."
fi

echo "===== UNINSTALLATION COMPLETE ====="
echo "You may want to restart your computer to ensure all components are fully removed."

# Ask if user wants to delete this script
read -p "Do you want to delete this uninstall script? (y/n): " delete_confirm

if [ "$delete_confirm" = "y" ]; then
    echo "Deleting uninstall script..."
    rm -f "$0"
    echo "Script deleted. Goodbye!"
fi