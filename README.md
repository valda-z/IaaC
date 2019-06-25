# IaaC

```bash
# create blob storage for our artifacts (RPM files, installation files, binary files).
export DEVOPS_UNIQUENAME=valdadevop001
export DEVOPS_BLOBSTORAGE_NAME=${DEVOPS_UNIQUENAME}sbs
export DEVOPS_ACR_NAME=${DEVOPS_UNIQUENAME}acr
export DEVOPS_RG=TST_DEVOPS
export LOCATION=northeurope

# create resource group
az group create --location ${LOCATION} --name ${DEVOPS_RG}

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
# .... blob is usualy there: 
RPMBLOB="https://${DEVOPS_BLOBSTORAGE_NAME}.blob.core.windows.net/assets/noarch/mysimpleapp-0.1.0H-0.noarch.rpm"
# generate SAS for RPM blob
end=`date -d "10 years" '+%Y-%m-%dT%H:%MZ'`
RPMBLOBSAS=$(az storage blob generate-sas --account-name ${DEVOPS_BLOBSTORAGE_NAME} -c assets -n "noarch/mysimpleapp-0.1.0H-0.noarch.rpm" --permissions r --expiry $end --https-only -o tsv)

# collect required information 
echo "export ACR_NAME=${DEVOPS_ACR_NAME}
export ACR_URL=${ACR_URL}
export ACR_KEY=${ACR_KEY}
export RPM=\"${RPMBLOB}?${RPMBLOBSAS}\""
```

rnd
openssl rand -base64 32

dd if=/dev/urandom bs=1 count=302 2>/dev/null | tr -dc _A-Z-a-z-0-9 | head -c6

password
https://github.com/Azure/azure-quickstart-templates/tree/master/101-vm-secure-password

https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-arm.md

https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/active-directory/managed-identities-azure-resources/qs-configure-template-windows-vm.md

https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-keyvault-parameter

https://github.com/Azure/azure-quickstart-templates/blob/master/201-key-vault-secret-create/azuredeploy.json


https://janikvonrotz.ch/2019/04/12/package-java-spring-boot-service-into-rpm/



