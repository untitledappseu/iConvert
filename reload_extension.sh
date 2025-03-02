#!/bin/bash

echo "Reloading Finder extension..."

# Unload the extension
pluginkit -e ignore -i at.untitledapps.iConvert.FinderExtension

# Kill Finder to force it to reload extensions
killall Finder

# Wait for Finder to restart
sleep 2

# Load the extension
pluginkit -e use -i at.untitledapps.iConvert.FinderExtension

echo "Finder extension reloaded. Please try using it again."