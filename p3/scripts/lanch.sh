#!/bin/bash

# Kill existing port-forward processes
echo "Stopping existing port-forward processes..."
sudo pkill -f "kubectl port-forward" || true
sudo pkill -f "argocd" || true

sudo k3d cluster delete iot-cluster
sudo k3d cluster create iot-cluster \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer \

sudo kubectl create namespace argocd
sudo kubectl create namespace dev
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo kubectl config set-context --current --namespace=argocd
sudo argocd login --insecure --core

echo "waiting for argocd to be ready..."
sudo kubectl wait --for=condition=ready --timeout=600s pods --all -n argocd

sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

sudo kubectl config set-context --current --namespace=dev
sudo kubectl apply -f ./confs/manifest.yaml
sudo kubectl apply -f ./confs/app.yaml

echo "Waiting for application to be ready..."
sudo kubectl wait --for=condition=ready --timeout=300s pods --all -n dev

echo "Checking services status..."
sudo kubectl get pods -n dev
sudo kubectl get services -n dev
sudo kubectl get ingress -n dev

echo ""
echo "=== Health Check ==="
if curl -s http://42app.localhost > /dev/null; then
    echo "✅ Application is responding at http://42app.localhost"
else
    echo "❌ Application is not responding. Check the logs:"
    echo "kubectl logs -n dev -l app=myapp"
    exit 1
fi

echo ""
echo "=== Services are ready ==="
echo "ArgoCD UI: https://localhost:8080"
echo "Username: admin"
echo "Password: $(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "Application: http://42app.localhost"
echo ""
echo "To test the application:"
echo "curl http://42app.localhost"

