# Part 2: K3s and Three Simple Applications

Configuration d'un serveur K3s avec 3 applications web accessibles via Ingress basé sur le hostname.

## Architecture
```
192.168.56.110
├── app1.com → app1 (1 replica)
├── app2.com → app2 (3 replicas)
└── default  → app3 (1 replica)
```

## Installation
```bash
make up
# ou
vagrant up
```

## Test
```bash
make test
# ou
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl http://192.168.56.110  # app3 par défaut
```

## Vérification
```bash
vagrant ssh mkaliszcS

# Vérifier les deployments
sudo kubectl get deployments

# Vérifier les pods (app2 doit avoir 3 réplicas)
sudo kubectl get pods

# Vérifier les services
sudo kubectl get services

# Vérifier l'Ingress
sudo kubectl get ingress
sudo kubectl describe ingress apps-ingress
```

## Fonctionnement

L'Ingress route le trafic selon le header `Host`:
- `Host: app1.com` → app1-service
- `Host: app2.com` → app2-service (load balancing sur 3 pods)
- Pas de Host / autre → app3-service (défaut)

## Structure
```
p2/
├── Makefile
├── Vagrantfile
├── scripts/
│   ├── script-provision.sh
│   └── test.sh
└── confs/
    ├── app-1-deployment.yaml
    ├── app-1-service.yaml
    ├── app-2-deployment.yaml (replicas: 3)
    ├── app-2-service.yaml
    ├── app-3-deployment.yaml
    ├── app-3-service.yaml
    └── Ingress.yaml
```

## Commandes
```bash
make up      # Démarrer
make down    # Détruire
make test    # Tester les routes
```