#!/bin/bash

# Run in first

# Check if packages are already installed
if ! command -v curl &> /dev/null || ! command -v vim &> /dev/null; then
  echo "Installing curl and vim..."
  sudo pacman -S --noconfirm curl vim
else
  echo "curl and vim already installed"
fi

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  sudo pacman -S --noconfirm docker
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker $USER
  echo "Docker installed. You may need to logout and login again for group changes to take effect."
else
  echo "Docker already installed"
fi

# # Install kubectl
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
# echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# # Install K3D
# curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# # Clear installation files
# rm -f kubectl kubectl.sha256

# Delete cluster then recreate it
k3d cluster delete dvergobbS 2>/dev/null || echo "Cluster dvergobbS doesn't exist"
k3d cluster create dvergobbS \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer

# List mounted clusters
k3d cluster list

echo ""
echo "Cluster created with ports 80 and 443 mapped to loadbalancer"