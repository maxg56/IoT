#!/bin/bash
set -e

# create user name and root for gitlab
GITLAB_PASS=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)
echo "machine gitlab.localhost
login root
password ${GITLAB_PASS}" | sudo tee ~/.netrc > /dev/null
sudo mv ~/.netrc /root/
sudo chmod 600 /root/.netrc

# clone repo
echo "📥 Clonage du dépôt GitLab local..."
if ! sudo git clone http://gitlab.localhost/root/mgedrot-argo-demo.git git_repo; then
  echo "❌ Erreur lors du clonage du dépôt GitLab"
  exit 1
fi

# clone repo from github
echo "📥 Clonage du dépôt source depuis GitHub..."
if ! sudo git clone https://github.com/damien-vergobbi/IoT.git git_source; then
  echo "❌ Erreur lors du clonage du dépôt GitHub"
  exit 1
fi

# copy from git_source to git_repo
sudo cp -r git_source/bonus/confs/* git_repo/ 2>/dev/null || echo "No confs to copy"

# del repo from github
sudo rm -rf git_source/

cd git_repo
echo "📝 Ajout et commit des modifications..."
sudo git add .
if sudo git diff --staged --quiet; then
  echo "ℹ️  Aucune modification à committer"
else
  sudo git commit -m "update: sync with source repository"
  echo "⬆️  Push des modifications..."
  sudo git push
fi
cd ..

# sudo kubectl apply -f ../confs/deploy.yaml

# Warning port-forward
GREEN="\033[32m"
RESET="\033[0m"
echo "${GREEN}PORT-FORWARD : sudo kubectl port-forward svc/svc-wil -n dev 8888:8080${RESET}"