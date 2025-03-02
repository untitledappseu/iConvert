#!/bin/bash

# Check if cwebp is installed
if ! command -v cwebp &> /dev/null; then
    echo "cwebp not found. Installing WebP tools..."

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Please install Homebrew first."
        echo "Visit https://brew.sh for installation instructions."
        exit 1
    fi

    # Install WebP tools using Homebrew
    brew install webp

    # Verify installation
    if command -v cwebp &> /dev/null; then
        echo "WebP tools installed successfully."
        echo "cwebp location: $(which cwebp)"
    else
        echo "Failed to install WebP tools."
        exit 1
    fi
else
    echo "WebP tools are already installed."
    echo "cwebp location: $(which cwebp)"
fi

# Check if dwebp is installed
if ! command -v dwebp &> /dev/null; then
    echo "dwebp not found. This is unusual as it should be installed with cwebp."
    echo "Try reinstalling WebP tools: brew reinstall webp"
    exit 1
else
    echo "dwebp location: $(which dwebp)"
fi

exit 0