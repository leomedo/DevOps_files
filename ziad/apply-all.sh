#!/bin/bash

# Apply all YAML files in the correct order
echo "Applying Kubernetes manifests in order..."

# Install cert-manager if not already installed
if ! kubectl get namespace cert-manager &> /dev/null; then
  echo "Installing cert-manager..."
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml
  
  echo "Waiting for cert-manager to be ready..."
  kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s
fi

# Apply manifests in the correct order
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f persistent-volumes.yaml
kubectl apply -f database.yaml
kubectl apply -f redis.yaml
kubectl apply -f configurator.yaml

# Wait for configurator job to complete
echo "Waiting for configurator job to complete..."
kubectl wait --for=condition=complete job/frappe-configurator -n frappe-men --timeout=300s || true

kubectl apply -f backend.yaml
kubectl apply -f websocket.yaml
kubectl apply -f workers.yaml
kubectl apply -f frontend.yaml
kubectl apply -f cluster-issuer.yaml
kubectl apply -f ingress.yaml

# Check deployment status
echo "Checking deployment status..."
kubectl get pods -n frappe-men
kubectl get svc -n frappe-men
kubectl get ingressroute -n frappe-men

echo "Deployment completed. Please configure your DNS to point men.appyinfo.com to your server IP: $(curl -s ifconfig.me)"

