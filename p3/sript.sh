#!/bin/bash

# Script: IoT Cluster Setup with ArgoCD
# Description: Automated setup of a k3d Kubernetes cluster with ArgoCD for IoT applications
# Prerequisites: k3d, kubectl, argocd CLI tools must be installed
# Usage: ./sript.sh
#
# This script will:
# 1. Verify all required CLI tools are installed
# 2. Create a k3d cluster named 'iot-cluster' with load balancer ports
# 3. Create necessary namespaces (argocd, dev)
# 4. Install ArgoCD in the cluster
# 5. Set up port-forwarding for ArgoCD UI access
# 6. Apply application configuration if app.yaml exists

set -euo pipefail

# Step 1: Check prerequisites
echo "Checking prerequisites..."

# Verify k3d is installed and available
if ! command -v k3d &> /dev/null; then
    echo "Error: k3d is not installed, please install it first"
    exit 1
fi
echo "✓ k3d is installed"

# Verify kubectl is installed and available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed, please install it first"
    exit 1
fi
echo "✓ kubectl is installed"

# Verify argocd CLI is installed and available
if ! command -v argocd &> /dev/null; then
    echo "Error: argocd is not installed, please install it first"
    exit 1
fi
echo "✓ argocd is installed"
# Step 2: Create k3d cluster
echo "Creating k3d cluster..."
# Create cluster with 1 agent node and expose ports 8080 and 8443 on the load balancer
if k3d cluster create iot-cluster --agents 1 --port '8080:80@loadbalancer' --port '8443:443@loadbalancer'; then
    echo "✓ k3d cluster created successfully"
else
    echo "Error: k3d cluster creation failed"
    exit 1
fi

# Verify cluster is running and accessible
echo "Verifying cluster nodes..."
kubectl get nodes || {
    echo "Error: Unable to get cluster nodes"
    exit 1
}

# Step 3: Create necessary namespaces
echo "Creating namespaces..."
# Create namespace for ArgoCD installation
kubectl create namespace argocd || {
    echo "Error: Failed to create argocd namespace"
    exit 1
}
# Create namespace for development applications
kubectl create namespace dev || {
    echo "Error: Failed to create dev namespace"
    exit 1
}

# Step 4: Install ArgoCD
echo "Installing ArgoCD..."
# Use official ArgoCD stable manifest from GitHub
ARGOCD_MANIFEST_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
echo "Downloading from: $ARGOCD_MANIFEST_URL"
kubectl apply -n argocd -f "$ARGOCD_MANIFEST_URL" || {
    echo "Error: Failed to install ArgoCD"
    exit 1
}

# Wait for ArgoCD pods to be ready (timeout after 5 minutes)
echo "Waiting for ArgoCD pods to be ready..."
sleep 30
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s || {
    echo "Warning: Some ArgoCD pods may not be ready yet"
    kubectl get pods -n argocd
}
# Step 5: Set up ArgoCD access
echo "Starting ArgoCD port-forward in background..."
# Forward ArgoCD server port to localhost:8080 for UI access
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
PORT_FORWARD_PID=$!
echo "Port-forward PID: $PORT_FORWARD_PID"

# Allow time for port-forward to establish connection
echo "Waiting for port-forward to establish..."
sleep 10

# Step 6: Retrieve ArgoCD admin credentials
echo "Getting ArgoCD admin password..."
if kubectl -n argocd get secret argocd-initial-admin-secret &> /dev/null; then
    echo "ArgoCD admin password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
    echo "Use username 'admin' and the above password to login to ArgoCD UI at http://localhost:8080"
else
    echo "Warning: ArgoCD initial admin secret not found. The server may not be ready yet."
fi

# Step 7: Apply application configuration
echo "Applying application configuration..."
if [ -f "app.yaml" ]; then
    kubectl apply -f app.yaml || {
        echo "Error: Failed to apply app.yaml"
        exit 1
    }
    echo "✓ Application configuration applied successfully"
else
    echo "Warning: app.yaml not found in current directory"
fi

# Final completion message
echo "Setup completed successfully!"
echo ""
echo "Summary:"
echo "- k3d cluster 'iot-cluster' is running"
echo "- ArgoCD is installed and accessible at http://localhost:8080"
echo "- Namespaces created: argocd, dev"
echo "- Port-forward running in background (PID: $PORT_FORWARD_PID)"
echo ""
echo "To stop the port-forward, run: kill $PORT_FORWARD_PID"