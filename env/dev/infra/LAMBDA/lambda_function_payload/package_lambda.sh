#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKING_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$(dirname "$SCRIPT_DIR")"
ZIP_FILE="$OUTPUT_DIR/lambda_function_payload.zip"

echo "Script directory: $SCRIPT_DIR"
echo "Working directory: $WORKING_DIR"
echo "Output ZIP file: $ZIP_FILE"

# Check if requirements.txt exists
if [ ! -f "$WORKING_DIR/requirements.txt" ]; then
    echo "Error: requirements.txt not found in $WORKING_DIR"
    exit 1
fi

# Clean up existing dependencies and ZIP file
echo "Cleaning up existing dependencies..."
rm -rf "$WORKING_DIR"/*.pyc "$WORKING_DIR"/__pycache__ "$WORKING_DIR"/*.dist-info "$WORKING_DIR"/*.egg-info
rm -rf "$WORKING_DIR"/aws_xray_sdk "$WORKING_DIR"/boto3 "$WORKING_DIR"/botocore
rm -rf "$WORKING_DIR"/aws_lambda_powertools "$WORKING_DIR"/loguru "$WORKING_DIR"/grafana_loki "$WORKING_DIR"/requests
rm -f "$ZIP_FILE"

# Install dependencies in a Lambda-compatible environment
echo "Installing dependencies..."
docker run --rm -v "$WORKING_DIR:/lambda" public.ecr.aws/lambda/python:3.9 \
    pip install --no-cache-dir -r /lambda/requirements.txt -t /lambda || {
    echo "Error: Failed to install dependencies"
    exit 1
}

# Log installed packages for debugging
docker run --rm -v "$WORKING_DIR:/lambda" public.ecr.aws/lambda/python:3.9 \
    pip list --path /lambda > "$WORKING_DIR/pip_list.txt"

# Create the ZIP file with deterministic output
echo "Creating ZIP file: $ZIP_FILE"
cd "$WORKING_DIR" || {
    echo "Error: Failed to change to $WORKING_DIR"
    exit 1
}
# Use -X to exclude extra file attributes and ensure consistent timestamps
if ! find . -type f -not -path "./*.pyc" -not -path "./__pycache__/*" -not -path "./*.dist-info/*" -not -path "./*.egg-info/*" | sort | zip -X -r "$ZIP_FILE" -@; then
    echo "Error: Failed to create ZIP file"
    exit 1
fi

echo "Lambda package created successfully at $ZIP_FILE"