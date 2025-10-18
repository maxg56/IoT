#!/bin/bash

sudo pacman -Syu --noconfirm

sudo pacman -S --noconfirm curl wget

# Install Vagrant from AUR (using yay if available, otherwise install manually)
if command -v yay &> /dev/null; then
    yay -S --noconfirm vagrant
else
    sudo pacman -S --noconfirm vagrant
fi

# Install Docker
sudo pacman -S --noconfirm docker docker-compose

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
sudo usermod -aG docker $USER

sudo pacman -S --noconfirm kubectl


# install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install VirtualBox
echo "Installing VirtualBox..."

# Check current kernel version
KERNEL_VERSION=$(uname -r)
echo "Current kernel: $KERNEL_VERSION"

# Check if kernel modules directory exists
if [ ! -d "/lib/modules/$KERNEL_VERSION" ]; then
    echo "ERROR: Kernel modules directory /lib/modules/$KERNEL_VERSION not found"
    echo "This usually means your kernel and installed headers don't match."
    echo "Please update your system and reboot:"
    echo "  sudo pacman -Syu"
    echo "  sudo reboot"
    exit 1
fi

# Remove any conflicting VirtualBox packages first
sudo pacman -Rns --noconfirm virtualbox-host-modules-arch virtualbox-host-dkms 2>/dev/null || true

# Always use DKMS for better compatibility with kernel updates
echo "Using DKMS for better kernel compatibility"
sudo pacman -S --noconfirm dkms virtualbox virtualbox-host-dkms linux-headers

# Check if headers match running kernel
HEADERS_VERSION=$(ls /usr/lib/modules/ 2>/dev/null | grep -E '^[0-9]' | sort -V | tail -1)
if [ "$HEADERS_VERSION" != "$KERNEL_VERSION" ]; then
    echo "WARNING: Kernel headers version ($HEADERS_VERSION) doesn't match running kernel ($KERNEL_VERSION)"
    echo "Installing matching headers..."
    # Try to install headers for the exact kernel version
    sudo pacman -S --noconfirm linux-headers
fi

# Build and install VirtualBox modules
echo "Building VirtualBox kernel modules..."
sudo dkms autoinstall

# Load VirtualBox kernel modules
echo "Loading VirtualBox kernel modules..."
sudo modprobe vboxdrv || {
    echo "Failed to load vboxdrv module. Trying manual DKMS build..."

    # Get VirtualBox version
    VBOX_VERSION=$(pacman -Q virtualbox | cut -d' ' -f2 | cut -d'-' -f1)

    # Remove and reinstall DKMS modules
    sudo dkms remove virtualbox --all 2>/dev/null || true
    sudo dkms add virtualbox/$VBOX_VERSION 2>/dev/null || true
    sudo dkms build virtualbox/$VBOX_VERSION -k $KERNEL_VERSION
    sudo dkms install virtualbox/$VBOX_VERSION -k $KERNEL_VERSION

    # Try loading again
    sudo modprobe vboxdrv || {
        echo "ERROR: Still cannot load VirtualBox modules."
        echo "This indicates a kernel/headers compatibility issue."
        echo ""
        echo "Please try:"
        echo "1. Update your system: sudo pacman -Syu"
        echo "2. Reboot to use the latest kernel"
        echo "3. Run this script again"
        echo ""
        echo "Current kernel: $KERNEL_VERSION"
        echo "Available headers: $(ls /usr/lib/modules/ 2>/dev/null | grep -E '^[0-9]' | tr '\n' ' ')"
        exit 1
    }
}

# Load additional VirtualBox modules
sudo modprobe vboxnetflt 2>/dev/null || echo "vboxnetflt module not needed or already loaded"
sudo modprobe vboxnetadp 2>/dev/null || echo "vboxnetadp module not needed or already loaded"

# Add current user to vboxusers group
sudo usermod -aG vboxusers $USER

# Verify modules are loaded
echo "Verifying VirtualBox modules:"
lsmod | grep vbox || echo "No VirtualBox modules found - may need reboot"

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

echo "Argo CD installed successfully!"