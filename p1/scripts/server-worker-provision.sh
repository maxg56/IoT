#!/bin/bash

# server-worker scripts 
# TODO : Waiting for theserver to be created so we can get the token and set up k3s in agent
echo "seting up the worker"

until [ -f /vagrant/token ]; do
	sleep 2
done

echo "File found !"

export K3S_TOK=$(cat /vagrant/token)

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$K3S_TOK sh -