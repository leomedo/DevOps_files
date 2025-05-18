#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Make apps.sh executable
chmod +x apps.sh

# Source the apps.sh to export APPS_JSON_BASE64
source ./apps.sh

# Verify APPS_JSON_BASE64 is set
if [ -z "${APPS_JSON_BASE64}" ]; then
  echo "Error: APPS_JSON_BASE64 is not set."
  exit 1
fi

echo "APPS_JSON_BASE64: ${APPS_JSON_BASE64}"
 
echo "APPS_JSON_BASE64 successfully set."

# Build the Docker image with the APPS_JSON_BASE64 argument without using cache
docker build \
  --no-cache \
  --build-arg APPS_JSON_BASE64="${APPS_JSON_BASE64}" \
  -t frappe-app:latest .

echo "Docker image 'frappe-app:latest' built successfully."

docker builder prune --all --force