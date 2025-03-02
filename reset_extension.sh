#!/bin/bash

echo "Completely resetting Finder extension..."

# Extension bundle ID
EXTENSION_ID="at.untitledapps.iConvert.FinderExtension"

# Unload the extension
echo "Unloading extension..."
pluginkit -e ignore -i $EXTENSION_ID

# Kill Finder to force it to reload extensions
echo "Killing Finder..."
killall Finder

# Wait for Finder to restart
sleep 2

# Remove any cached extension data
echo "Removing extension cache..."
rm -rf ~/Library/Caches/at.untitledapps.iConvert* 2>/dev/null
rm -rf ~/Library/Containers/at.untitledapps.iConvert* 2>/dev/null
rm -rf ~/Library/Group\ Containers/at.untitledapps.iConvert* 2>/dev/null

# Wait a moment
sleep 2

# Load the extension
echo "Loading extension..."
pluginkit -e use -i $EXTENSION_ID

# Check if extension is loaded
echo "Checking extension status..."
pluginkit -m | grep -i "iconvert"

echo "Finder extension reset complete. Please try using it again."