#!/bin/bash
# * server-worker scripts 

set -e

echo "[INFO] SW : seting up the worker."

export K3S_TOK=$(cat /vagrant/token)

echo "[INFO] SW : token found."

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$K3S_TOK sh -

echo "[INFO] SW : K3s agent installed and connected to server."