#!/bin/bash

BOLD="\033[1m"
ITALIC="\033[3m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# Add Git configuration
# sudo git config --global user.email "you@example.com"
# sudo git config --global user.name "Your Name"

# create user name and root for gitlab
username="root"

GITLAB_PASS=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)
echo "machine gitlab.k3d.gitlab.com
login ${username}
password ${GITLAB_PASS}" > ~/.netrc
chmod 600 ~/.netrc

# clone GitLab repo
git clone http://gitlab.k3d.gitlab.com/root/dvergobb.git git_repo

# Debug output
ls -la git_repo

# clone GitHub repo
git clone https://github.com/damien-vergobbi/dvergobb-iot.git git_dvergobb

# copy from git_dvergobb and git_repo
mv git_dvergobb/* git_repo/

# del repo from github
rm -rf git_dvergobb/

cd git_repo
git add *
git commit -m "update"
git push

# Debug output
git status

cd ..

kubectl apply -f ./conf/app-gitlab-local.yaml

# Write command
echo -e "\n${BOLD}Command to start wil-app:${RESET}"
echo -e "\tkubectl port-forward svc/svc-wil -n dev 8888:8080"
echo -e "Then visit ${ITALIC}http://localhost:8888${RESET}"
