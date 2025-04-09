#!/bin/bash

# Gets the current directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Navigate to the lambda_function_payload directory relative to the script's directory
cd "$SCRIPT_DIR" 

# Move to the parent folder where lambda_function_payload is
cd ../lambda_function_payload

# Install dependencies in the current directory (lambda_function_payload)
pip install -r requirements.txt -t .

# Creates the zip file (lambda_function_payload.zip) from the content in the directory
zip -r ../lambda_function_payload.zip .

# Go back to the root directory (or wherever you want to keep the ZIP file)
cd "$SCRIPT_DIR" 