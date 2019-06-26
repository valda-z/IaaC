#!/bin/bash

######################################################
# custom installation script
# parameters:
#   1) POSTGRESQL_URL
#   2) ACR_NAME
#   3) ACR_KEY
#   4) SPA_IMAGE
#   5) TODO_IMAGE
######################################################

# install dependencies - JAVA
yum install -y docker-ce docker-compose docker-ce-cli containerd.io sudo wget

# prepare files ---------------------
mkdir -f /var/opt/mysapp

POSTGRESQL_URL="$1"
ACR_NAME="$2"
ACR_KEY="$3"
SPA_IMAGE="$4"
TODO_IMAGE="$5"

echo "
[Unit]
Description=MyApp
After=network-online.target

[Service]
EnvironmentFile=/etc/myapp.env
Type=simple
WorkingDirectory=/var/opt/mysapp
ExecStart=docker login -u ${ACR_NAME} -p ${ACR_KEY} ${ACR_NAME}.azurecr.io && docker-compose up
RemainAfterExit=no
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
" > /usr/lib/systemd/system/myapp.service

echo "version: '3'
services:
  myappspa:
    image: ${SPA_IMAGE} 
    ports: 
      - '8080:8080'
  myapptodo:
    image: ${TODO_IMAGE} 
    ports: 
      - '8081:8080'
    environment: 
      POSTGRESQL_URL: \"${POSTGRESQL_URL}\"
" > /var/opt/mysapp/docker-compose.yaml

# create config file
echo "POSTGRESQL_URL=\"$1\"" > /etc/myapp.env

# install service
sudo systemctl enable myapp.service
sudo systemctl start myapp.service
