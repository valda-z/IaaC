# VM Scale Set balanced by Application Gateway with PostgreSQL, all security assets stored in KeyVault, provisioned via Azure Image Builder

Deploying VM scale set with application gateway, VMs will be installed automatically by extension script. 

Installation is done by creating managed images - content of VM images is created by Azure Image Builder (preview).

All security assets stored in KeyVault service (password for SQL server and SSL certificate for SSL offload), security assets are accessed by `user managed identity` which have access to KeyVault. 

Script will deploy:

* Linux (CentOS) based VMs with private IP address and Network Security Group enabling communication only from local VNET 
* PostgreSQL database as service, PostgreSQL connected directly to VLAN via Service End Point.
* Application gateway with public IP address has deployed basic rules which sends traffic myapp solution (running on port 8080).
* Application gateway will listen on ports 80 (for standard HTTP) and 443 (for HTTPS), we will use self sign certificate in base64 encoding, certificate and password are stored in template like default parameters.

Final architecture picture:
![](arch.png)

```bash
# go to directory with our experiment
cd 06-vmssappgw-keyvault-imgbuilder

# register preview for Image Builder
### register
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview
### wait for registration is done - aprox 15minutes, check status by
az feature show --namespace Microsoft.VirtualMachineImages \
  --name VirtualMachineTemplatePreview --query properties.state
### register new provider in Azure
az provider register -n Microsoft.VirtualMachineImages
### check registration status - wait for status "Registered"
az provider show -n Microsoft.VirtualMachineImages \
  --query registrationState

```

```bash
export RG=TST_06
export LOCATION=eastus2
# please use your unique name for keyvault!
export KEYVAULT=valdakv06x001

# create resource group
az group create --location ${LOCATION} --name ${RG}

# create keyvault in resource group
az keyvault create --name ${KEYVAULT}                       \
                   --resource-group ${RG}                   \
                   --location ${LOCATION}                   \
                   --enabled-for-deployment true            \
                   --enabled-for-disk-encryption true       \
                   --enabled-for-template-deployment true   \
                   --sku standard
export KEYVAULTID="$(az keyvault show -n ${KEYVAULT} -g ${RG} --query "id" -o tsv)"
# enable soft delete on keyvault
az keyvault update --name ${KEYVAULT} --resource-group ${RG} \
    --enable-purge-protection true --enable-soft-delete true

# generate random password for PostgreSQL and store it in keyvault (24 chars)
az keyvault secret set --name postgres-secret           \
                       --value "$(openssl rand -base64 24)"    \
                       --vault-name ${KEYVAULT}

# import our PFX certificate (also we can use keyvault to generate our certificates)
az keyvault certificate import  --vault-name ${KEYVAULT} \
                                -n appgwcert             \
                                -f mycert.pfx --password ""
# get certificate ID for application gateway
export CERTSID="https://${KEYVAULT}.vault.azure.net/secrets/appgwcert/"

# create identity
az identity create -n appidentity -g ${RG}
export IDENTITYID="$(az identity show -n appidentity -g ${RG} --query "id" -o tsv)"
export IDENTITYCLIENTID="$(az identity show -n appidentity -g ${RG} --query "clientId" -o tsv)"
export IDENTITYPRINCIPALID="$(az identity show -n appidentity -g ${RG} --query "principalId" -o tsv)"
# assign identity to keyvault
az keyvault set-policy -n ${KEYVAULT} --secret-permission get --object-id ${IDENTITYPRINCIPALID}

```

Now let's create our managed image - we will use for it Azure Image Builder which will run in separated resource group.

```bash
# Resource group for image builder
export RGIMG=TST_06_IMGBUILDER
export IMAGENAME="myimage-001"

# create RG
az group create --location ${LOCATION} --name ${RGIMG}

# assign role for azure system user "Azure Virtual Machine Image Builder"
az role assignment create \
    --assignee cf32a0cc-373c-47c9-9156-0db11f6a6dfc \
    --role Contributor \
    --scope $(az group show -n ${RGIMG} --query id -o tsv)

az group deployment create -g ${RGIMG} --template-file imgbuilder.json --parameters \
    rpmuri="${RPM}" \
    imagename="${IMAGENAME}"

az resource invoke-action \
     --resource-group ${RGIMG} \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n myimgBuilder \
     --action Run

# get Image ID for provisioning
export IMAGEID="$(az image show -g ${RGIMG} -n ${IMAGENAME} --query id -o tsv)"

```

Now let's deploy template with custom managed image

```bash
# run deployment
az group deployment create -g ${RG} --template-file azuredeploy.json --parameters \
    username="valda" \
    sshkey="$(cat ~/.ssh/id_rsa.pub)" \
    vmcount="2" \
    postgrename="valdatst06" \
    postgreuser="valda" \
    postgrepassword="$(az keyvault secret show -n postgres-secret --vault-name  ${KEYVAULT} --query 'value' -o tsv)" \
    identityid="${IDENTITYID}" \
    identityclientid="${IDENTITYCLIENTID}" \
    keyvault="${KEYVAULT}" \
    appgwCertSID="${CERTSID}" \
    imageID="${IMAGEID}" \
    artifactsLocation="https://raw.githubusercontent.com/valda-z/IaaC/master/06-vmssappgw-keyvault-imgbuilder/install.sh"

```

Now you can use Azure portal and navigate to your Resource group, on the `Application Balancer` resource you can grab public IP address and try to connect to our web application on standard http port 80.
`http://<YOUR_IP_ADDRESS>`
If it works you can also check if SSL connection to our application is working on address:
`https://<YOUR_IP_ADDRESS>`


