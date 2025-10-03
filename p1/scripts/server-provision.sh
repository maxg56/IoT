#!/bin/bash

# server script
# TODO : Setup k3s in controler mode

curl -sfL https://get.k3s.io | sh -

while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
	echo "Waiting for the token"
	sleep 3
done

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/token
sudo chmod 644 /vagrant/token

echo "K3s installed and token shared"