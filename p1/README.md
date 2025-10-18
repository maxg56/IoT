# Part 1: K3s and Vagrant

Configuration d'un cluster K3s avec 2 VMs utilisant Vagrant.

## Architecture

- **mkaliszcS** (192.168.56.110) - K3s Server/Controller
- **mkaliszcSW** (192.168.56.111) - K3s Agent/Worker

## Installation
```bash
vagrant up
```

## Vérification
```bash
# SSH sur le serveur
vagrant ssh mkaliszcS

# Vérifier les nodes
sudo k3s kubectl get nodes
```

Résultat attendu :
```
NAME                  STATUS   ROLES                  AGE
mkaliszcserver        Ready    control-plane,master   XXm
mkaliszcserverworker  Ready    <none>                 XXm
```

## Commandes utiles
```bash
vagrant up          # Démarrer
vagrant halt        # Arrêter
vagrant destroy     # Supprimer
vagrant status      # Statut
```

## Fonctionnement

1. Le serveur installe K3s et sauvegarde le token dans `/vagrant/token`
2. Le worker récupère le token et se connecte au serveur
3. Communication via le réseau privé 192.168.56.0/24

## Structure
```
p1/
├── Vagrantfile
└── scripts/
    ├── server-provision.sh
    └── server-worker-provision.sh
```