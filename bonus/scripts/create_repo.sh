#!/bin/bash
set -e

# Attendre que GitLab soit prêt
echo "⏳ Attente du démarrage complet de GitLab..."
until curl -s http://localhost:8929/users/sign_in > /dev/null; do
  sleep 5
done
  echo "✅ GitLab est prêt."

# Variables
ROOT_EMAIL="root@example.com"
ROOT_PASS="changeme123!"
REPO_NAME="mgedrot-argo-demo"

# Créer un access token pour le compte root
TOKEN=$(curl --request POST "http://localhost:8929/oauth/token" \
  --form "grant_type=password" \
  --form "username=root" \
  --form "password=$ROOT_PASS" \
  --form "scope=api" \
  | jq -r .access_token)

# Créer un projet GitLab automatiquement
curl --header "Authorization: Bearer $TOKEN" \
  --data "name=$REPO_NAME&visibility=public" \
  "http://localhost:8929/api/v4/projects"

echo "🎉 Projet '$REPO_NAME' créé automatiquement pour le compte root."