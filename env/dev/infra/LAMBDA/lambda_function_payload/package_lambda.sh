#!/bin/bash

# Get the directory where this script is located (resolves to path.module/lambda_function_payload)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define the working directory as the script's location (where requirements.txt and Lambda code live)
WORKING_DIR="$SCRIPT_DIR"

# Define the output ZIP file location (one level up from the script)
OUTPUT_DIR="$(dirname "$SCRIPT_DIR")"
ZIP_FILE="$OUTPUT_DIR/lambda_function_payload.zip"

# Echo for debugging
echo "Script directory: $SCRIPT_DIR"
echo "Working directory: $WORKING_DIR"
echo "Output ZIP file: $ZIP_FILE"

# Check if requirements.txt exists
if [ ! -f "$WORKING_DIR/requirements.txt" ]; then
    echo "Error: requirements.txt not found in $WORKING_DIR"
    exit 1
fi

# Clean up any existing dependencies to avoid conflicts
echo "Cleaning up existing dependencies..."
rm -rf "$WORKING_DIR"/*.pyc "$WORKING_DIR"/__pycache__ "$WORKING_DIR"/*.dist-info "$WORKING_DIR"/*.egg-info

# Install dependencies into the working directory
echo "Installing dependencies..."
if ! pip install -r "$WORKING_DIR/requirements.txt" -t "$WORKING_DIR"; then
    echo "Error: Failed to install dependencies"
    exit 1
fi

# Create the ZIP file from the working directory contents
echo "Creating ZIP file: $ZIP_FILE"
cd "$WORKING_DIR" || {
    echo "Error: Failed to change to $WORKING_DIR"
    exit 1
}
# Remove any existing ZIP file to avoid appending
rm -f "$ZIP_FILE"
if ! zip -r "$ZIP_FILE" . -x "*.pyc" -x "__pycache__/*" -x "*.dist-info/*" -x "*.egg-info/*"; then
    echo "Error: Failed to create ZIP file"
    exit 1
fi

echo "Lambda package created successfully at $ZIP_FILE"