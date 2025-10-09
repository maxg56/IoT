#!/bin/bash

set -e

echo "[INFO] Seting up the server."

curl -sfL https://get.k3s.io | sh -

echo "[INFO] K3S install success."

echo "[INFO] Waiting for K3s to be ready..."

until sudo k3s kubectl get node &>/dev/null; do
    sleep 2
done

sudo kubectl apply -f /home/vagrant/confs

echo "[INFO] Server is running."