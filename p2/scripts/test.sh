#!/bin/bash

GREEN='\033[0;32m'
PURPLE='\033[0;35m'
RESET='\033[0m'

echo "${GREEN}[INFO] : app1.com${RESET}"
curl -H "Host: app1.com" http://192.168.56.110

echo "${GREEN}[INFO] : app2.com${RESET}"
echo "${PURPLE}Test replica 1 :${RESET}"
curl -H "Host: app2.com" http://192.168.56.110
echo "${PURPLE}Test replica 2 :${RESET}"
curl -H "Host: app2.com" http://192.168.56.110
echo "${PURPLE}Test replica 3 :${RESET}"
curl -H "Host: app2.com" http://192.168.56.110

echo "${GREEN}[INFO] : app3.com${RESET}"
curl -H "Host: app3.com" http://192.168.56.110
curl http://192.168.56.110

