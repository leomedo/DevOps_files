#!/bin/bash

# This script updates all deployments to use IfNotPresent pull policy

# Update all deployment files to use IfNotPresent pull policy
echo "Updating all deployments to use IfNotPresent pull policy..."

# Update configurator.yaml
sed -i 's/image: frappe-app:latest/image: frappe-app:latest\n        imagePullPolicy: IfNotPresent/g' configurator.yaml

# Update backend.yaml
sed -i 's/image: frappe-app:latest/image: frappe-app:latest\n        imagePullPolicy: IfNotPresent/g' backend.yaml

# Update websocket.yaml
sed -i 's/image: frappe-app:latest/image: frappe-app:latest\n        imagePullPolicy: IfNotPresent/g' websocket.yaml

# Update workers.yaml (multiple occurrences)
sed -i 's/image: frappe-app:latest/image: frappe-app:latest\n        imagePullPolicy: IfNotPresent/g' workers.yaml

# Update frontend.yaml
sed -i 's/image: frappe-app:latest/image: frappe-app:latest\n        imagePullPolicy: IfNotPresent/g' frontend.yaml

echo "All deployments updated to use IfNotPresent pull policy."

# Delete the failed configurator job
echo "Deleting the failed configurator job..."
kubectl delete job frappe-configurator -n frappe-men

# Reapply the configurator job
echo "Reapplying the configurator job..."
kubectl apply -f configurator.yaml

echo "Done! Check the status with: kubectl get pods -n frappe-men"
