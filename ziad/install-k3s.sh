#!/bin/bash

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sleep 10

# Set up kubectl to use k3s config
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Install cert-manager
echo "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s

# Apply Kubernetes manifests in order
echo "Applying Kubernetes manifests..."
kubectl apply -f k3s/01-namespace/
kubectl apply -f k3s/02-config/
kubectl apply -f k3s/03-storage/
kubectl apply -f k3s/04-database/
kubectl apply -f k3s/05-redis/
kubectl apply -f k3s/06-configurator/

# Wait for configurator job to complete
echo "Waiting for configurator job to complete..."
kubectl wait --for=condition=complete job/frappe-configurator -n frappe-men --timeout=300s

# Apply remaining manifests
kubectl apply -f k3s/07-backend/
kubectl apply -f k3s/08-websocket/
kubectl apply -f k3s/09-workers/
kubectl apply -f k3s/10-frontend/
kubectl apply -f k3s/11-cert-manager/
kubectl apply -f k3s/12-ingress/

# Check deployment status
echo "Checking deployment status..."
kubectl get pods -n frappe-men
kubectl get svc -n frappe-men
kubectl get ingressroute -n frappe-men

echo "Deployment completed. Please configure your DNS to point men.appyinfo.com to your server IP: $(curl -s ifconfig.me)"
