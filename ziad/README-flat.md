# Deploying Frappe to k3s with Flat File Structure

This guide provides detailed instructions for deploying your Frappe application to k3s with SSL support using a flat file structure.

## Prerequisites

1. A server with at least 2GB RAM and 2 CPUs (recommended: 4GB RAM, 2 CPUs)
2. Ubuntu 20.04 or newer (or any Linux distribution)
3. Domain name (men.appyinfo.com) with DNS configured to point to your server's IP address
4. Root or sudo access to the server

## File Structure

All YAML files are placed directly in the k3s directory:

\`\`\`
k3s/
├── namespace.yaml
├── configmap.yaml
├── secrets.yaml
├── persistent-volumes.yaml
├── database.yaml
├── redis.yaml
├── configurator.yaml
├── backend.yaml
├── websocket.yaml
├── workers.yaml
├── frontend.yaml
├── cluster-issuer.yaml
├── ingress.yaml
├── install-k3s-flat.sh
├── backup-script.sh
└── README-flat.md
\`\`\`

## Deployment Order

When applying the YAML files manually, it's important to follow this order:

1. namespace.yaml
2. configmap.yaml and secrets.yaml
3. persistent-volumes.yaml
4. database.yaml and redis.yaml
5. configurator.yaml
6. backend.yaml, websocket.yaml, workers.yaml, and frontend.yaml
7. cluster-issuer.yaml and ingress.yaml

## Step 1: Install k3s

\`\`\`bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Set up kubectl to use k3s config
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config

# Verify installation
kubectl get nodes
\`\`\`

## Step 2: Build and Push Docker Image

\`\`\`bash
# Build the Docker image
docker build -t your-registry.com/frappe-app:latest .

# Push to registry
docker push your-registry.com/frappe-app:latest
\`\`\`

If you don't have a registry, you can use the local k3s containerd registry:

\`\`\`bash
# Load image directly into k3s
k3s ctr images import frappe-app.tar
\`\`\`

## Step 3: Update Image References

Update all deployment YAML files to use your Docker image:

\`\`\`bash
find k3s -type f -name "*.yaml" -exec sed -i 's|frappe-app:latest|your-registry.com/frappe-app:latest|g' {} \;
\`\`\`

## Step 4: Deploy the Application

Use the provided installation script:

\`\`\`bash
chmod +x k3s/install-k3s-flat.sh
./k3s/install-k3s-flat.sh
\`\`\`

Or apply the manifests manually in the correct order:

\`\`\`bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s

# Apply manifests in order
kubectl apply -f k3s/namespace.yaml
kubectl apply -f k3s/configmap.yaml
kubectl apply -f k3s/secrets.yaml
kubectl apply -f k3s/persistent-volumes.yaml
kubectl apply -f k3s/database.yaml
kubectl apply -f k3s/redis.yaml
kubectl apply -f k3s/configurator.yaml

# Wait for configurator job to complete
kubectl wait --for=condition=complete job/frappe-configurator -n frappe-men --timeout=300s

kubectl apply -f k3s/backend.yaml
kubectl apply -f k3s/websocket.yaml
kubectl apply -f k3s/workers.yaml
kubectl apply -f k3s/frontend.yaml
kubectl apply -f k3s/cluster-issuer.yaml
kubectl apply -f k3s/ingress.yaml
\`\`\`

## Step 5: Configure DNS

Get the external IP of your server:

\`\`\`bash
curl -s ifconfig.me
\`\`\`

Update your DNS A record for `men.appyinfo.com` to point to this IP address.

## Step 6: Set Up Backups

\`\`\`bash
chmod +x k3s/backup-script.sh
# Edit the script to set your backup directory
./k3s/backup-script.sh
\`\`\`

## Troubleshooting

### Check Pod Status

\`\`\`bash
kubectl get pods -n frappe-men
\`\`\`

### View Pod Logs

\`\`\`bash
kubectl logs -n frappe-men <pod-name>
\`\`\`

### Check Ingress Status

\`\`\`bash
kubectl get ingressroute -n frappe-men
\`\`\`

### Check Certificate Status

\`\`\`bash
kubectl get certificate -n frappe-men
\`\`\`

### Restart a Deployment

\`\`\`bash
kubectl rollout restart deployment/<deployment-name> -n frappe-men
