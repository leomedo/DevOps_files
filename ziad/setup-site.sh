#!/bin/bash

# This script sets up a new site in Frappe after all pods are running

# Wait for backend pod to be ready
echo "Waiting for backend pod to be ready..."
kubectl wait --for=condition=ready pod -l app=frappe-backend -n frappe-men --timeout=300s

# Get the backend pod name
BACKEND_POD=$(kubectl get pods -n frappe-men -l app=frappe-backend -o jsonpath="{.items[0].metadata.name}")

# Create a new site
echo "Creating a new site..."
kubectl exec -it -n frappe-men $BACKEND_POD -- bench new-site men.appyinfo.com \
  --admin-password admin \
  --db-root-password 123 \
  --install-app erpnext \
  --install-app zatca

# Set the site as default
echo "Setting site as default..."
kubectl exec -it -n frappe-men $BACKEND_POD -- bench use men.appyinfo.com

echo "Site setup complete! You can now access your site at https://men.appyinfo.com"
