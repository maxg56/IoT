#!/bin/bash

sudo kubectl delete deployment wil -n dev
sudo kubectl delete namespace argocd
k3d cluster delete dvergobbS