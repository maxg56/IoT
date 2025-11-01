#!/bin/bash

set -e  # Exit on error

BOLD="\033[1m"
ITALIC="\033[3m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${BOLD}${ITALIC}Synchronizing GitHub repo to GitLab...${RESET}\n"

# Configuration
GITLAB_REPO_NAME="mgedrot-argo-demo"
GITHUB_REPO_URL="https://github.com/maxg56/mgedrot-argo-demo.git"
GITLAB_USER="root"
WORK_DIR="git_sync_temp"

# Cleanup function
cleanup() {
  echo -e "${YELLOW}Cleaning up temporary files...${RESET}"
  cd /home/maxence/Documents/iot/IoT/bonus
  rm -rf ${WORK_DIR}
  rm -f ~/.netrc
}

# # Set trap to cleanup on exit
# trap cleanup EXIT

# Check if GitLab is accessible
echo -e "${GREEN}Checking GitLab accessibility...${RESET}"
if ! curl -s -f http://gitlab.k3d.gitlab.com > /dev/null; then
  echo -e "${RED}ERROR: GitLab is not accessible at http://gitlab.k3d.gitlab.com${RESET}"
  echo -e "${YELLOW}Make sure GitLab is running: kubectl get pods -n gitlab${RESET}"
  exit 1
fi
echo -e "${GREEN}✓ GitLab is accessible${RESET}"

# Get GitLab password
echo -e "${GREEN}Retrieving GitLab credentials...${RESET}"
GITLAB_PASS=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode 2>/dev/null)

if [ -z "$GITLAB_PASS" ]; then
  echo -e "${RED}ERROR: Could not retrieve GitLab password${RESET}"
  exit 1
fi
echo -e "${GREEN}✓ GitLab credentials retrieved${RESET}"

# Configure Git credentials
echo -e "${GREEN}Configuring Git credentials...${RESET}"
cat > ~/.netrc << EOF
machine gitlab.k3d.gitlab.com
login ${GITLAB_USER}
password ${GITLAB_PASS}
EOF
chmod 600 ~/.netrc

# Configure git user for commits
git config --global user.email "argocd@k3d.local" 2>/dev/null || true
git config --global user.name "ArgoCD Sync" 2>/dev/null || true

# Create work directory
cd /home/maxence/Documents/iot/IoT/bonus
rm -rf ${WORK_DIR}
mkdir -p ${WORK_DIR}
cd ${WORK_DIR}

# Clone GitLab repo (or create if doesn't exist)
echo -e "${GREEN}Cloning GitLab repo...${RESET}"
if git clone http://gitlab.k3d.gitlab.com/${GITLAB_USER}/${GITLAB_REPO_NAME}.git gitlab_repo 2>/dev/null; then
  echo -e "${GREEN}✓ GitLab repo cloned${RESET}"
else
  echo -e "${YELLOW}GitLab repo doesn't exist, it will be created on first push${RESET}"
  mkdir -p gitlab_repo
  cd gitlab_repo
  git init
  git remote add origin http://gitlab.k3d.gitlab.com/${GITLAB_USER}/${GITLAB_REPO_NAME}.git
  cd ..
fi

# Clone GitHub repo
echo -e "${GREEN}Cloning GitHub repo...${RESET}"
git clone ${GITHUB_REPO_URL} github_repo
echo -e "${GREEN}✓ GitHub repo cloned${RESET}"

# Sync files from GitHub to GitLab repo
echo -e "${GREEN}Syncing files...${RESET}"
cd gitlab_repo

# Initialize git if needed
if [ ! -d .git ]; then
  git init
  git remote add origin http://gitlab.k3d.gitlab.com/${GITLAB_USER}/${GITLAB_REPO_NAME}.git
fi

# Remove all files except .git
find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Copy all files from GitHub repo
cp -r ../github_repo/* . 2>/dev/null || true
cp ../github_repo/.gitignore . 2>/dev/null || true

echo -e "${GREEN}✓ Files synced${RESET}"

# Commit and push
echo -e "${GREEN}Committing changes...${RESET}"
git add -A

if git diff --cached --quiet; then
  echo -e "${YELLOW}No changes to commit${RESET}"
else
  git commit -m "Sync from GitHub: $(date '+%Y-%m-%d %H:%M:%S')" || {
    echo -e "${RED}Commit failed${RESET}"
    git status
    cd ../..
    exit 1
  }
  echo -e "${GREEN}Pushing to GitLab...${RESET}"

  # Try to push to main, then master, then current branch
  if git push -u origin main 2>/dev/null; then
    echo -e "${GREEN}✓ Pushed to main${RESET}"
  elif git push -u origin master 2>/dev/null; then
    echo -e "${GREEN}✓ Pushed to master${RESET}"
  elif git push -u origin HEAD 2>/dev/null; then
    echo -e "${GREEN}✓ Pushed to current branch${RESET}"
  else
    echo -e "${RED}Push failed, trying force push for initial commit...${RESET}"
    git push -u origin main --force 2>/dev/null || git push -u origin master --force
  fi
  echo -e "${GREEN}✓ Changes pushed to GitLab${RESET}"
fi

# Show status
echo -e "${GREEN}Repository status:${RESET}"
git remote -v

cd ../..

# Update ArgoCD application to use GitLab repo
echo -e "\n${GREEN}Updating ArgoCD application to use GitLab repo...${RESET}"
kubectl patch application myapp -n argocd --type='json' -p='[
  {"op": "replace", "path": "/spec/source/repoURL", "value": "http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/'${GITLAB_USER}'/'${GITLAB_REPO_NAME}'.git"}
]' 2>/dev/null || echo -e "${YELLOW}ArgoCD application not found, skipping...${RESET}"

# Apply manifests
echo -e "\n${GREEN}Applying Kubernetes manifests...${RESET}"
if [ -f ./confs/manifest.yaml ]; then
  kubectl apply -f ./confs/manifest.yaml
fi

if [ -f ./confs/app-gitlab-local.yaml ]; then
  kubectl apply -f ./confs/app-gitlab-local.yaml
fi

# Summary
echo -e "\n${BOLD}${GREEN}=== Sync Complete ===${RESET}"
echo -e "${GREEN}GitLab repo URL:${RESET} http://gitlab.k3d.gitlab.com/${GITLAB_USER}/${GITLAB_REPO_NAME}"
echo -e "${GREEN}ArgoCD will now sync from GitLab${RESET}"
echo -e "\n${BOLD}To verify:${RESET}"
echo -e "  kubectl get application myapp -n argocd"
echo -e "  argocd app get myapp --core"
echo -e "  curl http://will42.localhost"
