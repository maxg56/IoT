#!/bin/bash

BOLD="\033[1m"
ITALIC="\033[3m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${BOLD}${ITALIC}Initializing IoT Application Deployment...${RESET}\n"

# Add host entry if not exists
HOST_ENTRY="127.0.0.1 will42.localhost"
HOSTS_FILE="/etc/hosts"

if grep -q "will42.localhost" "$HOSTS_FILE"; then
    echo -e "${GREEN}Host entry already exists: will42.localhost${RESET}"
else
    echo -e "${GREEN}Adding host entry: will42.localhost${RESET}"
    echo "$HOST_ENTRY" | sudo tee -a "$HOSTS_FILE"
fi

kubectl config set-context --current --namespace=dev

# Deploy ingress and ArgoCD application
echo -e "${GREEN}Deploying ingress and ArgoCD application...${RESET}"
kubectl apply -f ./confs/manifest.yaml
kubectl apply -f ./confs/app.yaml

echo -e "${GREEN}Refreshing ArgoCD application...${RESET}"
kubectl config set-context --current --namespace=argocd
argocd app get myapp --core --refresh 2>/dev/null || echo "App not yet registered"

# Wait for ArgoCD to sync
echo -e "${GREEN}Waiting for ArgoCD to sync (up to 5 minutes)...${RESET}"
for i in {1..60}; do
  STATUS=$(argocd app get myapp --core 2>/dev/null | grep "Health Status:" | awk '{print $3}')
  SYNC=$(argocd app get myapp --core 2>/dev/null | grep "Sync Status:" | awk '{print $3}')

  if [ "$SYNC" = "Synced" ] && [ "$STATUS" = "Healthy" ]; then
    echo -e "${GREEN}✅ ArgoCD application is synced and healthy!${RESET}"
    break
  fi

  if [ $((i % 6)) -eq 0 ]; then  # Print every 30 seconds
    echo "  Status: Sync=${SYNC:-Unknown}, Health=${STATUS:-Unknown} (${i}/60)"
  fi

  if [ $i -eq 60 ]; then
    echo -e "${RED}Warning: Application did not sync in time. Current status: Sync=${SYNC}, Health=${STATUS}${RESET}"
  fi

  sleep 5
done

kubectl config set-context --current --namespace=dev

echo -e "${GREEN}Waiting for pods to be ready...${RESET}"
kubectl wait --for=condition=ready --timeout=120s pods --all -n dev 2>/dev/null || echo -e "${RED}Warning: Some pods may not be ready yet${RESET}"

echo -e "\n${GREEN}Checking services status...${RESET}"
kubectl get pods -n dev
kubectl get services -n dev
kubectl get ingress -n dev

echo ""
echo -e "${BOLD}=== Health Check ===${RESET}"
sleep 2  # Give ingress a moment to update

HTTP_CODE=$(curl -s -o /tmp/response.txt -w "%{http_code}" http://will42.localhost)
RESPONSE=$(cat /tmp/response.txt)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Application is responding at http://will42.localhost${RESET}"
    echo -e "${GREEN}Response: ${RESPONSE}${RESET}"
else
    echo -e "${RED}❌ Application returned HTTP ${HTTP_CODE}${RESET}"
    echo -e "${RED}Response: ${RESPONSE}${RESET}"
    echo ""
    echo -e "${RED}Check the logs with:${RESET}"
    echo "  kubectl logs -n dev -l app=myapp"
    echo "  kubectl describe ingress will42-ingress -n dev"
    echo "  argocd app get myapp --core"
    exit 1
fi
rm -f /tmp/response.txt

echo ""
echo -e "${BOLD}${GREEN}=== Services are ready ===${RESET}"
echo -e "${GREEN}ArgoCD UI:${RESET} https://localhost:8085"
echo -e "${GREEN}Username:${RESET} admin"
echo -e "${GREEN}Password:${RESET} $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo 'N/A')"
echo -e "${GREEN}Application:${RESET} http://will42.localhost"
echo ""
echo -e "${BOLD}To test the application:${RESET}"
echo "curl http://will42.localhost"
