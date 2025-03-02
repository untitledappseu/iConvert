#!/bin/bash

# Unload any ChromatOS extensions
pluginkit -m | grep -i chroma | awk "{print \$2}" | xargs -I{} pluginkit -e ignore -i {}

# Kill Finder to force it to reload extensions
killall Finder

# Remove any ChromatOS containers or caches
rm -rf ~/Library/Caches/*chroma* 2>/dev/null
rm -rf ~/Library/Containers/*chroma* 2>/dev/null
rm -rf ~/Library/Group\ Containers/*chroma* 2>/dev/null
rm -rf ~/Library/Application\ Support/*chroma* 2>/dev/null

# Reset Finder preferences related to ChromatOS
defaults delete com.apple.finder "Codetopia-ChromatOS-main" 2>/dev/null

echo "ChromatOS remnants have been cleaned up. Please restart your Mac to complete the process."
