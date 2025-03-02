#!/bin/bash

echo "Cleaning up any ChromatOS remnants..."
./cleanup_chromatoos.sh

echo "Unloading extension..."
pluginkit -e ignore -i at.untitledapps.iconvert.iconvert-Finder-Extension

echo "Killing any running instances..."
pkill -f "iConvert Finder Extension"

echo "Removing extension from system..."
pluginkit -m -v -i at.untitledapps.iconvert.iconvert-Finder-Extension

echo "Waiting for system to process changes..."
sleep 3

echo "Rebuilding project (this may take a moment)..."
xcodebuild -project iConvert.xcodeproj -scheme "iConvert Finder Extension" clean build

echo "Enabling extension..."
pluginkit -e use -i at.untitledapps.iconvert.iconvert-Finder-Extension

echo "Restarting Finder..."
killall Finder

echo "Extension has been rebuilt and reinstalled. You may need to restart your Mac for changes to fully take effect."
echo "After restarting, check System Settings > Privacy & Security > Extensions > Added Extensions to ensure iConvert is properly registered."