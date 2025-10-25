#!/bin/bash

# create user name and root for gitlab
GITLAB_PASS=$(sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)
echo "machine gitlab.localhost
login root
password ${GITLAB_PASS}" | sudo tee ~/.netrc > /dev/null
sudo mv ~/.netrc /root/
sudo chmod 600 /root/.netrc

# clone repo
sudo git clone http://gitlab.localhost/root/mgedrot-argo-demo.git git_repo

# clone repo from github
sudo git clone https://github.com/maxg56/mgedrot-argo-demo.git git_buthor

# copy from git_buthor and git_repo
sudo mv git_buthor/manifests git_repo/

# del repo from github
sudo rm -rf git_buthor/

cd git_repo
sudo git add *
sudo git commit -m "update"
sudo git push
cd ..

# sudo kubectl apply -f ../confs/deploy.yaml

# Warning port-forward
GREEN="\033[32m"
RESET="\033[0m"
echo "${GREEN}PORT-FORWARD : sudo kubectl port-forward svc/svc-wil -n dev 8888:8080${RESET}"