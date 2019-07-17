# IaaC

This LAN materials demonstrates few possible scenarios how to automatically deploy and operate infrastructure and applications.
Our experiments are using JAVA based application and for persistent layer we will use PostgreSQL database, in advanced scenarios we will use instead of simple JAVA app two docker containers (first one with single page HTML5 app and second with JAVA microservice REST API).

## Preparation steps

Before we will start with our experiments we will create Azure Container Registry where we will store final docker images with SPA application, JAVA REST API microservice and special docker image for building JAVA based apps into RPM installation packages.

Blob Storage is used for storing final RPM packages with our application.

#### Prepare ACR and Blob Storage

```bash
# define parameters for our deployment
# This parameter is used for creating Azure Container Registry and Blob Storage, parameter must be unique name.
export DEVOPS_UNIQUENAME=valdadevop001
# rest of parameters
export DEVOPS_BLOBSTORAGE_NAME=${DEVOPS_UNIQUENAME}sbs
export DEVOPS_ACR_NAME=${DEVOPS_UNIQUENAME}acr
export DEVOPS_RG=TST_DEVOPS
export LOCATION=northeurope

# create resource group
az group create --location ${LOCATION} --name ${DEVOPS_RG}

# create blob storage for our artifacts (RPM files, installation files, binary files).
# Create storage account
az storage account create -n $DEVOPS_BLOBSTORAGE_NAME \
    -g $DEVOPS_RG \
    -l $LOCATION \
    --sku Standard_LRS

# Get storage key and create container
export DEVOPS_BLOBSTORAGE_KEY=$(az storage account keys list -g $DEVOPS_RG -n $DEVOPS_BLOBSTORAGE_NAME --query [0].value -o tsv
)
az storage container create -n assets \
    --public-access off \
    --account-name $DEVOPS_BLOBSTORAGE_NAME \
    --account-key $DEVOPS_BLOBSTORAGE_KEY

#generate SAS
export DEVOPS_BLOBSTORAGE_SAS=$(az storage container generate-sas -n assets \
    --https-only --permissions dlrw --expiry `date -d "10 years" '+%Y-%m-%dT%H:%MZ'` \
    --account-name $DEVOPS_BLOBSTORAGE_NAME \
    --account-key $DEVOPS_BLOBSTORAGE_KEY -o tsv)

#create ACR
az acr create --name $DEVOPS_ACR_NAME --resource-group $DEVOPS_RG --sku Standard --location ${LOCATION} --admin-enabled true

# Get ACR_URL for future use with docker-compose and build
export ACR_URL=$(az acr show --name $DEVOPS_ACR_NAME --resource-group $DEVOPS_RG --query "loginServer" --output tsv)

# Get ACR key for our experiments
export ACR_KEY=$(az acr credential show --name $DEVOPS_ACR_NAME --resource-group $DEVOPS_RG --query "passwords[0].value" --output tsv)
```

#### Build our applications

In these steps we will build docker images with:

* Single Page Application - image based on nginx, application based on angular 1.4
* JAVA REST API microservice - JAVA spring-boot application
* RPM build image - image for building JAVA application and packaging it to RPM installation packages

And finally we will use RPM build docker image for building and packaging our JAVA application into RPM installation package. Build is done in Azure COntainer Instance where docker image will run (it will pull source codes from github and after build it upload RPM package to Blob Storage). 

In last steps we will generate SAS (Shared Access Signature) token for blob containing RPM package and print out variables which have to be stored for future usage.

```bash
# build 

mkdir myexperiment
cd myexperiment

# clone repo first
git clone https://github.com/valda-z/IaaC.git

# and now lets step into folder with project files.
cd IaaC

# build SPA application in ACR - build has to be done from folder with source codes: k8s-workshop-developer
echo v1 > ./src/solution/myappspa/version
az acr build --registry $DEVOPS_ACR_NAME --image myappspa:v1 ./src/solution/myappspa

# for purpose of lab create v2 of your app by only changing from v1 to v2 in version file and build container with v2 tag
echo v2 > ./src/solution/myappspa/version
az acr build --registry $DEVOPS_ACR_NAME --image myappspa:v2 ./src/solution/myappspa

# build JAVA microservice (spring-boot)
az acr build --registry $DEVOPS_ACR_NAME --image myapptodo:v1 ./src/solution/myapptodo

# build RPM build image
az acr build --registry $DEVOPS_ACR_NAME --image myrpmbuild:latest ./src/simpleapp/myrpmbuild

# build RPM package (build in ACR and push result to Blob Storage)
az container create -g ${DEVOPS_RG} -l ${LOCATION} \
  --name rpm --image ${ACR_URL}/myrpmbuild:latest \
  --restart-policy Never \
  --environment-variables \
  GIT_URL="https://github.com/valda-z/IaaC.git" \
  PROJECTDIR="src/simpleapp/myapptodo" \
  BLOBSTORAGE="${DEVOPS_BLOBSTORAGE_NAME}" \
  BLOBCONTAINER="assets" \
  SAS="${DEVOPS_BLOBSTORAGE_SAS}" \
  --registry-username ${DEVOPS_ACR_NAME} --registry-password "${ACR_KEY}"

# delete when container done
TMPSTAT=""
while [ "$TMPSTAT" != "Terminated" ]
do
    TMPSTAT=$(az container show --resource-group $DEVOPS_RG --name rpm --query containers[0].instanceView.currentState.state -o tsv)
    echo $TMPSTAT
done
az container delete -g ${DEVOPS_RG} -n rpm --yes

# generate SAS for RPM blob
# .... blob is usually there: 
RPMBLOB="https://${DEVOPS_BLOBSTORAGE_NAME}.blob.core.windows.net/assets/noarch/mysimpleapp-0.1.0H-0.noarch.rpm"
# generate SAS for RPM blob
end=`date -d "10 years" '+%Y-%m-%dT%H:%MZ'`
RPMBLOBSAS=$(az storage blob generate-sas --account-name ${DEVOPS_BLOBSTORAGE_NAME} -c assets -n "noarch/mysimpleapp-0.1.0H-0.noarch.rpm" --permissions r --expiry $end --https-only -o tsv)

# collect required information - store export variables for future use
echo "export ACR_NAME=${DEVOPS_ACR_NAME}
export ACR_URL=${ACR_URL}
export ACR_KEY=${ACR_KEY}
export ACR_ID=$(az acr show --resource-group ${DEVOPS_RG} --name ${DEVOPS_ACR_NAME} --query id --output tsv)
export RPM=\"${RPMBLOB}?${RPMBLOBSAS}\""
```

## Experiments

### [01 - Single VM hosts mysimpleapp](01-singlevm/)

### [02 - Couple of VMs with load balancer host mysimpleapp](02-balancedvm)

### [03 - VM Scale set with load balancer hosts mysimpleapp](03-vmscaleset)

### [04 - VM Scale Set with Application Gateway hosts containerized apps](04-vmssappgw)

### [05 - VM Scale Set with Application Gateway hosts containerized apps + KeyVault for storing secrets](05-vmssappgw-keyvault)

## Useful links

https://github.com/Azure/azure-quickstart-templates/tree/master/101-vm-secure-password

https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-arm.md

https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/active-directory/managed-identities-azure-resources/qs-configure-template-windows-vm.md

https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-keyvault-parameter

https://github.com/Azure/azure-quickstart-templates/blob/master/201-key-vault-secret-create/azuredeploy.json


https://janikvonrotz.ch/2019/04/12/package-java-spring-boot-service-into-rpm/



