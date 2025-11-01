# IoT Bonus - Installation GitLab sur cluster k3d

## Prérequis

Ce projet utilise le cluster k3d `dvergobbS` créé dans la partie P3.

## Ordre d'installation

### 1. Créer le cluster k3d (depuis P3)

```bash
cd /home/maxence/Documents/iot/IoT/p3
./scripts/1_k3d.sh
```

Cela crée le cluster `dvergobbS` avec les ports 80 et 443 mappés.

### 2. Installer GitLab

```bash
cd /home/maxence/Documents/iot/IoT/bonus
./scripts/install.sh
```

Ce script va :
- Vérifier que le cluster `dvergobbS` existe
- Installer GitLab via Helm
- Configurer l'ingress Traefik
- Afficher les identifiants de connexion

**Temps d'installation** : 10-20 minutes (GitLab est lourd)

### 3. Synchroniser le repo (optionnel)

```bash
cd /home/maxence/Documents/iot/IoT/bonus
./scripts/swap_repo.sh
```

## Accès GitLab

- **URL** : http://gitlab.k3d.gitlab.com
- **Username** : root
- **Password** : Affiché par install.sh

## Vérification

```bash
# Vérifier le cluster
k3d cluster list

# Vérifier les pods GitLab
kubectl get pods -n gitlab

# Vérifier l'ingress
kubectl get ingress -n gitlab
```
