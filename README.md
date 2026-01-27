# IoT - Infrastructure Kubernetes & GitOps

Ce projet explore le déploiement et la gestion d'applications conteneurisées à travers quatre parties progressives, de la configuration d'un cluster Kubernetes de base jusqu'à l'implémentation d'une solution GitOps complète avec GitLab.

## 📋 Vue d'ensemble

Le projet est structuré en quatre parties de complexité croissante :

- **P1** : Configuration d'un cluster K3s avec Vagrant (serveur + worker)
- **P2** : Déploiement de 3 applications web avec routage Ingress
- **P3** : Implémentation GitOps avec ArgoCD sur K3D
- **Bonus** : Installation de GitLab sur le cluster K3D

## 🏗️ Structure du projet

```
IoT/
├── p1/                 # K3s cluster avec Vagrant
│   ├── Vagrantfile
│   └── scripts/
│       ├── server-provision.sh
│       └── server-worker-provision.sh
│
├── p2/                 # Déploiement d'applications K3s
│   ├── Vagrantfile
│   ├── Makefile
│   ├── scripts/
│   │   ├── script-provision.sh
│   │   └── test.sh
│   └── confs/
│       └── [YAML files for apps and ingress]
│
├── p3/                 # ArgoCD & GitOps
│   ├── scripts/
│   │   ├── install_dep.sh
│   │   ├── 1_k3d.sh
│   │   ├── 2_argocd.sh
│   │   ├── 3_init.sh
│   │   └── delete_all.sh
│   └── confs/
│       ├── app.yaml
│       └── manifest.yaml
│
└── bonus/              # Installation GitLab
    ├── scripts/
    │   ├── install.sh
    │   └── swap_repo.sh
    └── confs/
        └── [GitLab configurations]
```

## 🛠️ Technologies utilisées

- **Orchestration** : K3s, K3D, Kubernetes
- **Virtualisation** : Vagrant, VirtualBox
- **GitOps** : ArgoCD
- **CI/CD** : GitLab
- **Ingress** : Traefik
- **Conteneurs** : Docker
- **Package Manager** : Helm

## 📦 Prérequis généraux

Selon la partie du projet :

**Pour P1 et P2** :
- Vagrant
- VirtualBox
- Au moins 4 GB de RAM disponible

**Pour P3 et Bonus** :
- Docker
- kubectl
- Helm
- K3D
- Au moins 8 GB de RAM disponible (pour GitLab)

---

## 🚀 Partie 1 : Cluster K3s avec Vagrant

### Description

Configuration d'un cluster Kubernetes K3s minimal avec deux machines virtuelles :
- Un serveur K3s (192.168.56.110)
- Un worker K3s (192.168.56.111)

### Déploiement

```bash
cd p1
vagrant up
```

### Vérification

```bash
# Connectez-vous au serveur
vagrant ssh mkaliszcS

# Vérifiez les nœuds
kubectl get nodes
```

### Nettoyage

```bash
vagrant destroy -f
```

---

## 🌐 Partie 2 : Applications Web avec Ingress

### Description

Déploiement de trois applications web avec routage basé sur le hostname :
- **app1.com** : 1 réplica (containous/whoami)
- **app2.com** : 3 réplicas avec load balancing
- **app3** : Route par défaut

### Déploiement

```bash
cd p2
make up
```

### Tests

```bash
# Test automatique des trois applications
make test

# Tests manuels
curl --resolve app1.com:80:192.168.56.110 http://app1.com
curl --resolve app2.com:80:192.168.56.110 http://app2.com
curl http://192.168.56.110  # app3 par défaut
```

### Nettoyage

```bash
make down
```

---

## 🔄 Partie 3 : ArgoCD & GitOps

### Description

Mise en place d'un système de déploiement continu avec ArgoCD sur un cluster K3D. L'application est automatiquement synchronisée depuis un repository Git.

### Architecture

- **Cluster** : K3D (`dvergobbS`)
- **Ports exposés** : 80, 443
- **Namespaces** : `argocd`, `dev`
- **Application** : wil42/playground:v2

### Installation

```bash
cd p3

# 1. Installer les dépendances
./scripts/install_dep.sh

# 2. Créer le cluster K3D
./scripts/1_k3d.sh

# 3. Installer ArgoCD
./scripts/2_argocd.sh

# 4. Déployer l'application
./scripts/3_init.sh
```

### URLs d'accès

- **ArgoCD UI** : https://localhost:8085
  - Username: `admin`
  - Password: affiché dans le terminal

- **Application** : http://will42.localhost

### Tests

```bash
curl http://will42.localhost
# Réponse attendue : {"status":"ok", "message": "v2"}
```

### Debugging

```bash
# Vérifier les pods
kubectl get pods -n dev
kubectl get pods -n argocd

# Vérifier l'ingress
kubectl get ingress -n dev

# Logs de l'application
kubectl logs -n dev -l app=myapp
```

### Nettoyage

```bash
./scripts/delete_all.sh
```

---

## 🦊 Bonus : Installation GitLab

### Description

Installation complète de GitLab sur le cluster K3D pour gérer des repositories Git et des pipelines CI/CD.

### Prérequis

Le cluster K3D de la partie P3 doit être créé :

```bash
cd p3
./scripts/1_k3d.sh
```

### Installation

```bash
cd bonus
./scripts/install.sh
```

⏱️ **Temps d'installation** : 10-20 minutes (GitLab est lourd)

### Accès GitLab

- **URL** : http://gitlab.k3d.gitlab.com
- **Username** : root
- **Password** : Affiché par le script install.sh

### Synchronisation du repository (optionnel)

```bash
./scripts/swap_repo.sh
```

### Vérification

```bash
# Vérifier le cluster
k3d cluster list

# Vérifier les pods GitLab
kubectl get pods -n gitlab

# Vérifier l'ingress
kubectl get ingress -n gitlab
```

---

## 🔍 Commandes utiles

### K3s/Kubernetes

```bash
# Lister tous les pods
kubectl get pods --all-namespaces

# Lister les services
kubectl get svc --all-namespaces

# Lister les ingress
kubectl get ingress --all-namespaces

# Logs d'un pod
kubectl logs <pod-name> -n <namespace>

# Décrire une ressource
kubectl describe pod <pod-name> -n <namespace>
```

### K3D

```bash
# Lister les clusters
k3d cluster list

# Arrêter un cluster
k3d cluster stop <cluster-name>

# Démarrer un cluster
k3d cluster start <cluster-name>

# Supprimer un cluster
k3d cluster delete <cluster-name>
```

### Vagrant

```bash
# Statut des VMs
vagrant status

# Se connecter à une VM
vagrant ssh <vm-name>

# Redémarrer une VM
vagrant reload <vm-name>

# Suspendre les VMs
vagrant suspend

# Reprendre les VMs
vagrant resume
```

---

## 📝 Notes importantes

### P1 & P2
- Les VMs utilisent le réseau privé 192.168.56.0/24
- K3s est installé sur Alpine Linux 3.18
- Le serveur K3s exporte automatiquement son token pour le worker

### P3
- ArgoCD synchronise automatiquement l'application depuis GitHub
- Self-heal activé : l'application se remet automatiquement en état désiré
- Prune activé : les ressources supprimées du Git sont automatiquement supprimées du cluster
- Le repository source : https://github.com/maxg56/mgedrot-argo-demo.git

### Bonus
- GitLab nécessite au moins 8 GB de RAM
- L'installation prend 10-20 minutes
- GitLab utilise Helm pour le déploiement
- Le mot de passe root est généré automatiquement

---

## 🐛 Troubleshooting

### P1/P2 - Vagrant ne démarre pas
```bash
# Vérifier VirtualBox
VBoxManage --version

# Supprimer les VMs corrompues
vagrant destroy -f
rm -rf .vagrant/
vagrant up
```

### P3 - ArgoCD n'est pas accessible
```bash
# Vérifier le port-forward
kubectl port-forward -n argocd svc/argocd-server 8085:443

# Récupérer le mot de passe
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Bonus - GitLab ne démarre pas
```bash
# Vérifier l'état des pods
kubectl get pods -n gitlab

# Vérifier les logs
kubectl logs -n gitlab -l app=gitlab

# GitLab prend du temps à démarrer (10-20 min)
# Patience ! ☕
```

---

## 📄 Licence

Ce projet est sous licence Apache 2.0. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 👥 Contributeurs

Projet réalisé dans le cadre d'un cursus IoT / Infrastructure as Code.

---

## 📚 Ressources

- [Documentation K3s](https://docs.k3s.io/)
- [Documentation K3D](https://k3d.io/)
- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
- [Documentation GitLab](https://docs.gitlab.com/)
- [Documentation Vagrant](https://www.vagrantup.com/docs)
