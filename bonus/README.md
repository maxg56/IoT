# IoT Bonus Project - GitLab CI/CD avec ArgoCD

Ce projet démontre l'implémentation d'un pipeline CI/CD complet utilisant GitLab et ArgoCD pour le déploiement automatisé d'applications dans un cluster Kubernetes.

## 📋 Table des matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Scripts disponibles](#scripts-disponibles)
- [Dépannage](#dépannage)

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Source Code   │    │     GitLab      │    │    ArgoCD       │
│   (GitHub)      │───▶│   (Local K8s)   │───▶│  (Deployment)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                         │
                              ▼                         ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  CI/CD Pipeline │    │   Dev Namespace │
                       │   Automation    │    │  (Application)  │
                       └─────────────────┘    └─────────────────┘
```

### Composants principaux :

- **K3D Cluster** : Cluster Kubernetes léger pour le développement
- **GitLab** : Instance locale pour la gestion du code et CI/CD
- **ArgoCD** : Outil de déploiement GitOps
- **Application** : Déployée dans le namespace `dev`

## 🔧 Prérequis

### Système requis :
- **OS** : Arch Linux (ou distribution basée sur Arch)
- **RAM** : 8GB minimum, 16GB recommandé
- **CPU** : 4 cores minimum
- **Stockage** : 20GB d'espace libre

### Outils requis :
- Docker
- kubectl
- k3d
- ArgoCD CLI
- VirtualBox (optionnel)
- Vagrant (optionnel)

## 🚀 Installation

### 1. Installation des dépendances

```bash
cd /path/to/iot/IoT/bonus
chmod +x scripts/install_dep.sh
./scripts/install_dep.sh
```

Ce script installe automatiquement :
- Docker et Docker Compose
- kubectl
- k3d
- VirtualBox avec modules DKMS
- ArgoCD CLI
- Vagrant

### 2. Redémarrage requis

Après l'installation, redémarrez votre système pour charger les modules du noyau :

```bash
sudo reboot
```

## ⚙️ Configuration

### Structure des fichiers

```
bonus/
├── confs/
│   └── app-gitlab-local.yaml    # Configuration ArgoCD Application
├── scripts/
│   ├── install_dep.sh          # Installation des dépendances
│   ├── lanch.sh               # Déploiement principal
│   ├── create_repo.sh         # Création du dépôt GitLab
│   └── update_repo.sh         # Synchronisation du code
└── README.md                  # Cette documentation
```

### Variables d'environnement

Les scripts supportent les variables d'environnement suivantes :

```bash
# Pour create_repo.sh
export ROOT_EMAIL="your-email@example.com"
export ROOT_PASS="your-secure-password"
export REPO_NAME="your-repo-name"
```

## 🎯 Utilisation

### Déploiement complet

```bash
# 1. Lancer le déploiement principal
cd /path/to/iot/IoT/bonus
chmod +x scripts/lanch.sh
./scripts/lanch.sh
```

### Accès aux services

Après le déploiement réussi :

#### ArgoCD
- **URL** : https://localhost:8080
- **Username** : `admin`
- **Password** : Affiché dans le terminal après déploiement

#### Application
- **URL** : http://will42.localhost
- **Namespace** : `dev`

### Création et synchronisation du dépôt GitLab

```bash
# Créer un nouveau dépôt dans GitLab local
./scripts/create_repo.sh

# Synchroniser avec le code source
./scripts/update_repo.sh
```

## 📝 Scripts disponibles

### `install_dep.sh`
**Fonction** : Installation automatique de toutes les dépendances système

**Fonctionnalités** :
- Installation des paquets Arch Linux requis
- Configuration de Docker avec permissions utilisateur
- Installation et configuration de VirtualBox avec DKMS
- Gestion intelligente des conflits de modules noyau
- Installation d'ArgoCD CLI

**Usage** :
```bash
./scripts/install_dep.sh
```

### `lanch.sh`
**Fonction** : Déploiement principal du cluster et des applications

**Fonctionnalités** :
- Création/recréation du cluster K3D
- Déploiement d'ArgoCD
- Configuration des namespaces
- Port-forwarding automatique
- Vérification de l'état des services

**Usage** :
```bash
./scripts/lanch.sh
```

### `create_repo.sh`
**Fonction** : Création automatique d'un dépôt GitLab

**Fonctionnalités** :
- Attente du démarrage complet de GitLab
- Authentification automatique
- Création de projet via API
- Gestion d'erreurs avec validation

**Variables** :
- `ROOT_EMAIL` : Email du compte root
- `ROOT_PASS` : Mot de passe (récupéré automatiquement si non défini)
- `REPO_NAME` : Nom du dépôt

**Usage** :
```bash
# Avec variables par défaut
./scripts/create_repo.sh

# Avec variables personnalisées
ROOT_EMAIL="admin@company.com" REPO_NAME="my-project" ./scripts/create_repo.sh
```

### `update_repo.sh`
**Fonction** : Synchronisation du code source avec GitLab

**Fonctionnalités** :
- Récupération automatique des credentials GitLab
- Clonage sécurisé des dépôts
- Synchronisation intelligente des fichiers
- Commit et push automatiques

**Usage** :
```bash
./scripts/update_repo.sh
```

## 🔍 Vérification du déploiement

### Commandes utiles

```bash
# Vérifier l'état du cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Vérifier ArgoCD
kubectl get pods -n argocd
kubectl get svc -n argocd

# Vérifier l'application
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get ingress -n dev

# Logs des applications
kubectl logs -n dev -l app=myapp
kubectl logs -n argocd deployment/argocd-server
```

### Tests de connectivité

```bash
# Test de l'application
curl -v http://will42.localhost

# Test d'ArgoCD
curl -k https://localhost:8080

# Vérification du port-forwarding
ss -tulpn | grep :8080
```

## 🛠️ Dépannage

### Problèmes courants

#### 1. Erreurs de modules VirtualBox
```bash
# Vérifier les modules chargés
lsmod | grep vbox

# Recompiler les modules si nécessaire
sudo dkms autoinstall
sudo modprobe vboxdrv
```

#### 2. Cluster K3D non accessible
```bash
# Supprimer et recréer le cluster
k3d cluster delete iot-bonus
k3d cluster create iot-bonus --port 80:80@loadbalancer --port 443:443@loadbalancer
```

#### 3. ArgoCD non accessible
```bash
# Vérifier le port-forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Récupérer le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

#### 4. Application non déployée
```bash
# Vérifier les ressources ArgoCD
kubectl get applications -n argocd
kubectl describe application myapp -n argocd

# Forcer la synchronisation
argocd app sync myapp
```

### Logs de débogage

```bash
# Logs détaillés ArgoCD
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-server

# Logs de l'application
kubectl logs -n dev deployment/myapp
kubectl describe pod -n dev -l app=myapp
```

### Nettoyage complet

```bash
# Supprimer le cluster
k3d cluster delete iot-bonus

# Nettoyer les conteneurs Docker
docker system prune -a

# Supprimer les données persistantes (optionnel)
sudo rm -rf ~/.k3d/
```

## 📚 Ressources supplémentaires

- [Documentation K3D](https://k3d.io/)
- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
- [Documentation GitLab](https://docs.gitlab.com/)
- [Documentation Kubernetes](https://kubernetes.io/docs/)

## 🤝 Contribution

Pour contribuer à ce projet :

1. Fork le dépôt
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est à des fins éducatives dans le cadre du cursus IoT.