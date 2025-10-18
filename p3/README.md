# P3 - ArgoCD & Kubernetes Deployment

Cette partie du projet IoT met en place un système de déploiement continu avec ArgoCD sur un cluster K3D.

## Architecture

- **K3D** : Cluster Kubernetes local
- **ArgoCD** : Outil de déploiement GitOps
- **Traefik** : Ingress controller pour la gestion du trafic
- **Application** : Service web basé sur l'image `wil42/playground:v2`

## Structure du projet

```
p3/
├── scripts/
│   ├── install_dep.sh    # Installation des dépendances
│   └── lanch.sh          # Script de lancement principal
└── confs/
    ├── app.yaml          # Configuration ArgoCD Application
    └── manifest.yaml     # Manifestes Kubernetes (Service, Ingress)
```

## Déploiement

### Prérequis

Exécuter le script d'installation des dépendances :
```bash
./scripts/install_dep.sh
```

### Lancement

Exécuter le script principal :
```bash
./scripts/lanch.sh
```

Le script effectue automatiquement :
1. Nettoyage des processus existants
2. Création du cluster K3D `iot-cluster`
3. Installation d'ArgoCD
4. Déploiement de l'application
5. Configuration de l'ingress
6. Vérifications de santé

## URLs d'accès

Une fois le déploiement terminé, les services sont accessibles via :

- **ArgoCD UI** : https://localhost:8080
  - Username: `admin`
  - Password: affiché dans le terminal après déploiement

- **Application** : http://will42.localhost
  - API endpoint retournant `{"status":"ok", "message": "v2"}`

## Tests

Tester l'application :
```bash
curl http://will42.localhost
```

Réponse attendue :
```json
{"status":"ok", "message": "v2"}
```

## Composants Kubernetes

### Service
- **Nom** : `myapp`
- **Port** : 8888
- **Namespace** : `dev`

### Ingress
- **Nom** : `will42-ingress`
- **Host** : `will42.localhost`
- **Controller** : Traefik

### ArgoCD Application
- **Repository** : https://github.com/maxg56/mgedrot-argo-demo.git
- **Path** : `.` (racine du repo)
- **Destination** : namespace `dev`
- **Sync Policy** : Automatique avec prune et self-heal

## Debugging

### Vérifier les pods
```bash
kubectl get pods -n dev
kubectl logs -n dev -l app=myapp
```

### Vérifier les services
```bash
kubectl get services -n dev
kubectl get ingress -n dev
```

### Vérifier ArgoCD
```bash
kubectl get pods -n argocd
```

### Port-forward manuel si besoin
```bash
kubectl port-forward -n dev svc/myapp 8888:8888
```

## Notes

- Le cluster utilise les ports 80 et 443 du load balancer
- L'application redémarre automatiquement en cas de problème (self-heal)
- Les changements dans le repository Git sont automatiquement déployés