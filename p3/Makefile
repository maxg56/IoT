# IoT Cluster Management Makefile
# Description: Easy management of k3d cluster with ArgoCD for IoT applications
# Usage: make <target>

.PHONY: help mkstart mkdown mkreux status clean logs password

# Default target
help:
	@echo "IoT Cluster Management Commands:"
	@echo ""
	@echo "  mkstart    - Start/create the IoT cluster with ArgoCD"
	@echo "  mkdown     - Stop and remove the IoT cluster"
	@echo "  mkreux     - Recreate the cluster (down + start)"
	@echo "  status     - Show cluster and ArgoCD status"
	@echo "  logs       - Show ArgoCD server logs"
	@echo "  password   - Get ArgoCD admin password"
	@echo "  clean      - Clean up all resources"
	@echo "  help       - Show this help message"

# Variables
CLUSTER_NAME = iot-cluster
ARGOCD_NAMESPACE = argocd
DEV_NAMESPACE = dev
ARGOCD_MANIFEST = https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Check prerequisites
check-prereqs:
	@echo "Checking prerequisites..."
	@command -v k3d >/dev/null 2>&1 || { echo "Error: k3d is required but not installed"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl is required but not installed"; exit 1; }
	@command -v argocd >/dev/null 2>&1 || { echo "Error: argocd CLI is required but not installed"; exit 1; }
	@echo "✓ All prerequisites are installed"

# Start/create the cluster
mkstart: check-prereqs
	@echo "Starting IoT cluster setup..."
	@if k3d cluster list | grep -q $(CLUSTER_NAME); then \
		echo "Cluster $(CLUSTER_NAME) already exists, starting it..."; \
		k3d cluster start $(CLUSTER_NAME); \
	else \
		echo "Creating new cluster $(CLUSTER_NAME)..."; \
		k3d cluster create $(CLUSTER_NAME) --agents 1 \
			--port '8080:80@loadbalancer' \
			--port '8443:443@loadbalancer'; \
	fi
	@echo "Verifying cluster..."
	@kubectl get nodes
	@echo "Creating namespaces..."
	@kubectl create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace $(DEV_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "Installing ArgoCD..."
	@kubectl apply -n $(ARGOCD_NAMESPACE) -f $(ARGOCD_MANIFEST)
	@echo "Waiting for ArgoCD to be ready..."
	@kubectl wait --for=condition=Ready pods --all -n $(ARGOCD_NAMESPACE) --timeout=300s || true
	@echo "Starting port-forward in background..."
	@pkill -f "kubectl port-forward.*argocd-server" || true
	@kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:443 >/dev/null 2>&1 &
	@sleep 5
	@if [ -f "app.yaml" ]; then \
		echo "Applying application configuration..."; \
		kubectl apply -f app.yaml; \
	fi
	@echo ""
	@echo "✓ IoT cluster is ready!"
	@echo "✓ ArgoCD UI: http://localhost:8080"
	@echo "✓ Username: admin"
	@echo "✓ Password: run 'make password' to get it"

# Stop and remove the cluster
mkdown:
	@echo "Stopping IoT cluster..."
	@echo "Stopping port-forward processes..."
	@pkill -f "kubectl port-forward.*argocd-server" 2>/dev/null || true
	@sleep 2
	@echo "Deleting k3d cluster..."
	@timeout 30 k3d cluster delete $(CLUSTER_NAME) 2>/dev/null || true
	@echo "Waiting for cleanup to complete..."
	@sleep 3
	@echo "✓ Cluster $(CLUSTER_NAME) stopped and removed"

# Recreate the cluster
mkreux:
	@echo "Recreating IoT cluster..."
	@$(MAKE) mkdown
	@sleep 2
	@$(MAKE) mkstart
	@echo "✓ Cluster recreated successfully"

# Show cluster status
status:
	@echo "=== Cluster Status ==="
	@if k3d cluster list | grep -q $(CLUSTER_NAME); then \
		echo "✓ Cluster $(CLUSTER_NAME) exists"; \
		kubectl get nodes 2>/dev/null || echo "✗ Cluster not accessible"; \
	else \
		echo "✗ Cluster $(CLUSTER_NAME) does not exist"; \
	fi
	@echo ""
	@echo "=== ArgoCD Status ==="
	@if kubectl get namespace $(ARGOCD_NAMESPACE) >/dev/null 2>&1; then \
		echo "✓ ArgoCD namespace exists"; \
		kubectl get pods -n $(ARGOCD_NAMESPACE) 2>/dev/null || echo "✗ Cannot get ArgoCD pods"; \
	else \
		echo "✗ ArgoCD namespace does not exist"; \
	fi
	@echo ""
	@echo "=== Port Forward Status ==="
	@if pgrep -f "kubectl port-forward.*argocd-server" >/dev/null; then \
		echo "✓ ArgoCD port-forward is running"; \
		echo "  UI available at: http://localhost:8080"; \
	else \
		echo "✗ ArgoCD port-forward is not running"; \
	fi

# Get ArgoCD admin password
password:
	@echo "ArgoCD Admin Password:"
	@kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d && echo "" || echo "Password not available (cluster may not be ready)"

# Show ArgoCD logs
logs:
	@echo "ArgoCD Server Logs:"
	@kubectl logs -n $(ARGOCD_NAMESPACE) -l app.kubernetes.io/name=argocd-server --tail=50

# Clean up everything
clean:
	@echo "Performing full cleanup..."
	@$(MAKE) mkdown
	@echo "Cleaning up Docker resources..."
	@docker system prune -f 2>/dev/null || true
	@echo "Removing any remaining k3d resources..."
	@docker container ls -a | grep k3d | awk '{print $$1}' | xargs -r docker rm -f 2>/dev/null || true
	@echo "✓ Full cleanup completed"

# Start port-forward manually
port-forward:
	@echo "Starting ArgoCD port-forward..."
	@pkill -f "kubectl port-forward.*argocd-server" || true
	@kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:443

# Stop port-forward
stop-port-forward:
	@echo "Stopping ArgoCD port-forward..."
	@pkill -f "kubectl port-forward.*argocd-server" || true
	@echo "✓ Port-forward stopped"