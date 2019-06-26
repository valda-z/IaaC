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
yum install -y docker sudo wget epel-release
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

systemctl enable docker
systemctl start docker

# prepare files ---------------------
mkdir -p /var/opt/myapp

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
Type=simple
WorkingDirectory=/var/opt/myapp
ExecStart=/bin/bash /var/opt/myapp/run.sh
RemainAfterExit=no
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
" > /usr/lib/systemd/system/myapp.service

echo "#!/bin/bash
cd /var/opt/myapp
/usr/bin/docker login -u ${ACR_NAME} -p ${ACR_KEY} ${ACR_NAME}.azurecr.io
/usr/bin/docker-compose up
" > /var/opt/myapp/run.sh
chmod +x /var/opt/myapp/run.sh

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
" > /var/opt/myapp/docker-compose.yaml

# install service
sudo systemctl enable myapp.service
sudo systemctl start myapp.service
