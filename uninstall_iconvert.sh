#!/bin/bash

echo "Starting complete uninstallation of iConvert..."

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
rm -rf "/Applications/iConvert.app" 2>/dev/null

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

echo "Uninstallation complete. You may want to restart your computer to ensure all components are fully removed."