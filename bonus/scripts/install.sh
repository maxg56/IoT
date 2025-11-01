#!/bin/bash

BOLD="\033[1m"
ITALIC="\033[3m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# install git if not already installed
if ! command -v git &> /dev/null; then
  echo -e "${GREEN}Installing git...${RESET}"
  sudo pacman -S --noconfirm git
else
  echo -e "${GREEN}Git is already installed, skipping...${RESET}"
fi

# Check if k3d cluster exists, if not create it
if ! k3d cluster list | grep -q "dvergobbS"; then
  echo -e "${RED}ERROR: Cluster 'dvergobbS' not found!${RESET}"
  echo -e "${GREEN}Please run the p3 cluster creation script first:${RESET}"
  echo "  cd /home/maxence/Documents/iot/IoT/p3 && ./scripts/1_k3d.sh"
  exit 1
else
  echo -e "${GREEN}Using existing cluster 'dvergobbS'...${RESET}"
  k3d cluster start dvergobbS 2>/dev/null || echo "Cluster already running"
fi

# Wait for cluster to be ready
echo -e "${GREEN}Waiting for cluster to be ready...${RESET}"
sleep 5

# after install k3d cluster create gitlab namespace
kubectl create namespace gitlab 2>/dev/null || echo "Namespace gitlab already exists"

# cheking and add host
HOST_ENTRY="127.0.0.1 gitlab.k3d.gitlab.com"
HOSTS_FILE="/etc/hosts"

if grep -q "$HOST_ENTRY" "$HOSTS_FILE"; then
    echo "exist $HOSTS_FILE"
else
    echo "adding $HOSTS_FILE"
    echo "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE"
fi
 
echo -e "${GREEN}Adding GitLab Helm repository...${RESET}"
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || echo "Repo already added"
echo -e "${GREEN}Updating Helm repositories...${RESET}"
helm repo update
echo -e "${GREEN}Installing GitLab (this may take several minutes)...${RESET}"
helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  --set global.hosts.domain=k3d.gitlab.com \
  --set global.hosts.externalIP=0.0.0.0 \
  --set global.hosts.https=false \
  --timeout 600s

echo -e "${GREEN}Waiting for GitLab to be ready (this can take 10-20 minutes)...${RESET}"
kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab || echo -e "${RED}Warning: GitLab may still be starting up. Check with: kubectl get pods -n gitlab${RESET}"

# Create Traefik ingress for GitLab (k3d uses Traefik by default)
echo -e "${GREEN}Creating Traefik ingress for GitLab...${RESET}"
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gitlab-webservice-traefik
  namespace: gitlab
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik
  rules:
  - host: gitlab.k3d.gitlab.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gitlab-webservice-default
            port:
              number: 8181
EOF

echo -e "${GREEN}Waiting for ingress to be ready...${RESET}"
sleep 5

echo -e "\n${BOLD}${GREEN}Gitlab username :${RESET}${GREEN} root${RESET}"
echo -e "${BOLD}${GREEN}Gitlab password :${RESET}${GREEN} $(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)${RESET}"
echo -e "${BOLD}${GREEN}GitLab URL :${RESET} http://gitlab.k3d.gitlab.com"
echo -e "${BOLD}${GREEN}Alternative URL :${RESET} http://localhost:8080 (requires port-forward)"
echo -e "\nTo start port-forward: kubectl port-forward svc/gitlab-webservice-default -n gitlab 8080:8181"