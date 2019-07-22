#!/bin/bash

######################################################
# custom installation script
# parameters:
#   1) POSTGRESQL 
#   2) CLIENTID
#   3) KEYVAULT_NAME
#   4) KEYVAULT_SECRET
######################################################

echo "POSTGRESQL=\"$1\"
CLIENTID=\"$2\"
KEYVAULT_NAME=\"$3\"
KEYVAULT_SECRET\"$4\"
" > /etc/mysimpleapp.env
