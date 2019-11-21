#!/bin/bash

######################################################
# custom installation script
# parameters:
#   1) POSTGRESQL_URL
#   2) ACR_NAME
#   3) IDENTITYID
#   4) KEYVAULT_NAME
#   5) SPA_IMAGE
#   6) TODO_IMAGE
######################################################

# install az CLI
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install -y azure-cli

# install dependencies - docker
sudo yum install -y docker sudo wget epel-release jq
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

systemctl enable docker
systemctl start docker

# prepare files ---------------------
mkdir -p /var/opt/myapp

POSTGRESQL_URL="$1"
ACR_NAME="$2"
IDENTITYID="$3"
KEYVAULT_NAME="$4"
SPA_IMAGE="$5"
TODO_IMAGE="$6"

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
# login to azure
az login --identity --username "${IDENTITYID}"
# login to ACR
az acr login --name $ACR_NAME
# collect PostgreSQL password
POSTGRESPWD=\"\$(az keyvault secret show -n postgres-secret --vault-name ${KEYVAULT_NAME} --query 'value' -o tsv)\";
POSTGRESPWD=\${POSTGRESPWD//+/%2B}
POSTGRESPWD=\${POSTGRESPWD////%2F}
POSTGRESPWD=\${POSTGRESPWD//=/%3D}
export POSTGRESQL_URL=\"${POSTGRESQL_URL}&password=\${POSTGRESPWD}\"
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
      POSTGRESQL_URL: \${POSTGRESQL_URL}
" > /var/opt/myapp/docker-compose.yaml

# install service
sudo systemctl enable myapp.service
sudo systemctl start myapp.service
