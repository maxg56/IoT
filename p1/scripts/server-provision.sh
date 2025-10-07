#!/bin/bash
# * server script

set -e

echo "[INFO] S : seting up the server."

curl -sfL https://get.k3s.io | sh -

echo "[INFO] S : K3S install success."

echo "[INFO] S : Waiting for K3s to be ready..."

until sudo k3s kubectl get node &>/dev/null; do
    sleep 2
done

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/token

sudo chmod 644 /vagrant/token

echo "[INFO] S : K3s token shared, server is running."
