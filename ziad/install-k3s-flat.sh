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

# Apply Kubernetes manifests in the correct order
echo "Applying Kubernetes manifests in order..."

# 1. First apply namespace
kubectl apply -f namespace.yaml

# 2. Apply config and secrets
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml

# 3. Apply storage
kubectl apply -f persistent-volumes.yaml

# 4. Apply database and redis
kubectl apply -f database.yaml
kubectl apply -f redis.yaml

# 5. Apply configurator
kubectl apply -f configurator.yaml

# Wait for configurator job to complete
echo "Waiting for configurator job to complete..."
kubectl wait --for=condition=complete job/frappe-configurator -n frappe-men --timeout=300s

# 6. Apply backend, websocket, workers, and frontend
kubectl apply -f backend.yaml
kubectl apply -f websocket.yaml
kubectl apply -f workers.yaml
kubectl apply -f frontend.yaml

# 7. Apply cert-manager and ingress
kubectl apply -f cluster-issuer.yaml
kubectl apply -f ingress.yaml

# Check deployment status
echo "Checking deployment status..."
kubectl get pods -n frappe-men
kubectl get svc -n frappe-men
kubectl get ingressroute -n frappe-men

echo "Deployment completed. Please configure your DNS to point men.appyinfo.com to your server IP: $(curl -s ifconfig.me)"
