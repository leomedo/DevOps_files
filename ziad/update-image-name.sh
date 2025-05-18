#!/bin/bash

# Replace with the exact image name from the previous command
EXACT_IMAGE_NAME="docker.io/library/frappe-app:latest"

# Update all YAML files
find . -name "*.yaml" -type f -exec sed -i "s|image: frappe-app:latest|image: $EXACT_IMAGE_NAME|g" {} \;

echo "All YAML files updated to use $EXACT_IMAGE_NAME"