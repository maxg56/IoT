#!/bin/bash
set -euo pipefail

# === COLORS ===
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
RESET="\033[0m"

# === CLEANUP HANDLER ===
cleanup() {
  echo -e "${YELLOW}🧹 Cleaning up background processes...${RESET}"
  kill $(jobs -p) 2>/dev/null || true
}
trap cleanup EXIT

# === CLUSTER CREATION ===
echo -e "${CYAN}🔧 Recreating K3D cluster...${RESET}"

if k3d cluster list | grep -q "iot-bonus"; then
  echo -e "${YELLOW}Cluster 'iot-bonus' already exists. Deleting...${RESET}"
  k3d cluster delete iot-bonus || true
fi

k3d cluster create iot-bonus \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer

# === NAMESPACES ===
echo -e "${CYAN}📦 Creating namespaces...${RESET}"
for ns in argocd dev gitlab; do
  if ! kubectl get ns "$ns" &>/dev/null; then
    kubectl create ns "$ns"
  else
    echo -e "${YELLOW}Namespace '$ns' already exists, skipping.${RESET}"
  fi
done

# === DEPLOY GITLAB ===
echo -e "${CYAN}🚀 Deploying GitLab components...${RESET}"
kubectl apply -f ./confs/gitlab-namespace.yaml
kubectl apply -f ./confs/gitlab-storage.yaml
kubectl apply -f ./confs/gitlab-deployment.yaml
kubectl apply -f ./confs/gitlab-service.yaml
kubectl apply -f ./confs/gitlab-ingress.yaml

# === DEPLOY ARGOCD ===
echo -e "${CYAN}⚙️  Deploying ArgoCD...${RESET}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# === WAIT FOR COMPONENTS ===
echo -e "${YELLOW}⏳ Waiting for GitLab to be ready (this can take 5–10 min)...${RESET}"
kubectl wait --for=condition=ready pod --all -n gitlab --timeout=900s || true

echo -e "${YELLOW}⏳ Waiting for ArgoCD to be ready...${RESET}"
kubectl wait --for=condition=ready pod --all -n argocd --timeout=600s || true

# === LOGIN TO ARGOCD ===
echo -e "${CYAN}🔐 Logging into ArgoCD...${RESET}"
kubectl config set-context --current --namespace=argocd
argocd login --insecure --core

# === PORT FORWARD ===
echo -e "${CYAN}🌐 Starting ArgoCD port-forward on :8080...${RESET}"
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &

# === DEPLOY DEV APP ===
echo -e "${CYAN}🧱 Deploying application to namespace 'dev'...${RESET}"
kubectl config set-context --current --namespace=dev
kubectl apply -f ./confs/manifest.yaml
kubectl apply -f ./confs/app-gitlab-local.yaml

echo -e "${YELLOW}⏳ Waiting for application pods to be ready...${RESET}"
kubectl wait --for=condition=ready pod --all -n dev --timeout=300s || true

# === STATUS CHECKS ===
echo -e "${CYAN}🔍 Checking services status...${RESET}"
kubectl get pods -n dev
kubectl get services -n dev
kubectl get ingress -n dev

echo -e "\n${CYAN}=== Health Check ===${RESET}"
if curl -s http://will42.localhost >/dev/null; then
  echo -e "${GREEN}✅ Application is responding at http://will42.localhost${RESET}"
else
  echo -e "${RED}❌ Application is not responding.${RESET}"
  echo "Run: kubectl logs -n dev -l app=myapp"
  exit 1
fi

# === FINAL SUMMARY ===
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

echo -e "\n${GREEN}=== 🚀 Deployment Summary ===${RESET}"
echo -e "📦 ${CYAN}GitLab:${RESET} http://gitlab.localhost (or http://localhost:30800)"
echo -e "   Username: root"
echo -e "   Password: changeme123!"
echo ""
echo -e "🧭 ${CYAN}ArgoCD:${RESET} https://localhost:8080"
echo -e "   Username: admin"
echo -e "   Password: ${YELLOW}${ARGO_PWD}${RESET}"
echo ""
echo -e "🌍 ${CYAN}Application:${RESET} http://will42.localhost"
echo ""
echo -e "🩺 To check GitLab:"
echo "   kubectl get pods -n gitlab"
echo "   kubectl logs -n gitlab deployment/gitlab"
echo ""
echo -e "${GREEN}✅ All systems deployed successfully!${RESET}"
