#!/bin/bash

# Stop the extension
pluginkit -e use -i at.untitledapps.iConvert.FinderExtension

# Kill the extension process
pkill -f "iConvert Finder Extension"

# Unload the extension
pluginkit -m -v -i at.untitledapps.iConvert.FinderExtension

# Wait a moment
sleep 2

# Enable the extension
pluginkit -e use -i at.untitledapps.iConvert.FinderExtension

# Restart Finder
killall Finder

echo "Extension has been reloaded. You may need to restart your Mac for changes to fully take effect."