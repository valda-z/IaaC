#!/bin/bash

######################################################
# custom installation script
# parameters:
#   1) POSTGRESQL_URL
#   2) RPM blob storage URL including SAS
######################################################

# install dependencies - JAVA
yum install -y java-1.8.0-openjdk sudo wget

# install app ---------------------
wget "$2" -O app.rpm

# create config file
echo "POSTGRESQL_URL=\"$1\"" > /etc/mysimpleapp.env

# install service
yum install -y app.rpm
