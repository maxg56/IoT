#!/bin/bash

# Run in second

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# Delete namespaces then recreate it
kubectl delete namespace argocd 2>/dev/null || echo "Namespace argocd doesn't exist"
kubectl delete namespace dev 2>/dev/null || echo "Namespace dev doesn't exist"

kubectl create namespace argocd
kubectl create namespace dev

# Install Argo CD in kubectl
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Add host in VM hosts if not exists
HOST_ENTRY="127.0.0.1 argocd.dvergobb.com"
HOSTS_FILE="/etc/hosts"

if grep -q "$HOST_ENTRY" "$HOSTS_FILE"; then
    echo "Host entry already exists: $HOST_ENTRY"
else
    echo "Adding host entry: $HOST_ENTRY"
    echo "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE"
fi

kubectl config set-context --current --namespace=argocd
argocd login --insecure --core

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready --timeout=600s pods --all -n argocd

# password to argocd (user: admin)
echo -e "\n${BOLD}${GREEN}Argo CD username :${RESET}${GREEN} admin${RESET}"
echo -e "${BOLD}${GREEN}Argo CD password :${RESET}${GREEN} $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)${RESET}"

# Start Argo CD on localhost:8085 or argocd.dvergobb.com:8085
echo -e "${GREEN}Starting port-forward on localhost:8085...${RESET}"
kubectl port-forward svc/argocd-server -n argocd 8085:443 > /dev/null 2>&1 &

echo -e "\n${BOLD}${GREEN}ArgoCD is ready!${RESET}"
echo -e "${GREEN}URL:${RESET} https://localhost:8085 or https://argocd.dvergobb.com:8085"