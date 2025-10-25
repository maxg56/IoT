#!/bin/bash
set -e

# Attendre que GitLab soit prêt
echo "⏳ Attente du démarrage complet de GitLab..."
until curl -s http://localhost:8929/users/sign_in > /dev/null; do
  sleep 5
done
  echo "✅ GitLab est prêt."

# Variables
ROOT_EMAIL="${ROOT_EMAIL:-root@example.com}"
ROOT_PASS="${ROOT_PASS:-$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode 2>/dev/null || echo 'changeme123!')}"
REPO_NAME="${REPO_NAME:-mgedrot-argo-demo}"

# Créer un access token pour le compte root
echo "🔑 Création du token d'accès..."
TOKEN=$(curl --silent --request POST "http://localhost:8929/oauth/token" \
  --form "grant_type=password" \
  --form "username=root" \
  --form "password=$ROOT_PASS" \
  --form "scope=api" \
  | jq -r .access_token)

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Erreur lors de la création du token d'accès"
  exit 1
fi

# Créer un projet GitLab automatiquement
echo "📁 Création du projet '$REPO_NAME'..."
RESPONSE=$(curl --silent --header "Authorization: Bearer $TOKEN" \
  --data "name=$REPO_NAME&visibility=public" \
  "http://localhost:8929/api/v4/projects")

if echo "$RESPONSE" | jq -e '.id' > /dev/null; then
  echo "🎉 Projet '$REPO_NAME' créé automatiquement pour le compte root."
else
  echo "❌ Erreur lors de la création du projet: $RESPONSE"
  exit 1
fi