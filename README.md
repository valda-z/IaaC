# IaaC

```bash
# create blob storage for our artifacts (RPM files, installation files, binary files).
export DEVOPS_BLOBSTORAGE_NAME=valdadevopsbs001
export DEVOPS_BLOBSTORAGE_RG=DEVOPS_STORAGE
export LOCATION=northeurope

# create resource group
az group create --location ${LOCATION} --name ${DEVOPS_BLOBSTORAGE_RG}

# Create storage account
az storage account create -n $DEVOPS_BLOBSTORAGE_NAME \
    -g $DEVOPS_BLOBSTORAGE_RG \
    -l $LOCATION \
    --sku Standard_LRS

# Get storage key and create container
export DEVOPS_BLOBSTORAGE_KEY=$(az storage account keys list -g $DEVOPS_BLOBSTORAGE_RG -n $DEVOPS_BLOBSTORAGE_NAME --query [0].value -o tsv
)
az storage container create -n assets \
    --public-access off \
    --account-name $DEVOPS_BLOBSTORAGE_NAME \
    --account-key $DEVOPS_BLOBSTORAGE_KEY
#generate SAS
SAS=$(az storage container generate-sas -n assets \
    --https-only --permissions dlrw --expiry `date -d "10 years" '+%Y-%m-%dT%H:%MZ'` \
    --account-name $DEVOPS_BLOBSTORAGE_NAME \
    --account-key $DEVOPS_BLOBSTORAGE_KEY -o tsv)

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



