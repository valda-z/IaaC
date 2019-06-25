# Single VM deployment with PostgreSQL

Deploying single VM with public IP address, VM will be installed automatically by cloud-init script. 

Installation requires prepared RPM packege stored somewhere - in our case we are using Azure blob storage.

```bash
cd 01-simplevm
```

```bash
export RG=TST_01
export LOCATION=northeurope

# create resource group
az group create --location ${LOCATION} --name ${RG}

# run deployment
az group deployment create -g ${RG} --template-file azuredeploy.json --parameters \
    username="valda" \
    sshkey="$(cat ~/.ssh/id_rsa.pub)" \
    postgrename="valdatst01" \
    postgreuser="valda" \
    postgrepassword="pwd123..." \
    rpmurl="${RPM}" \
    artifactsLocation="https://raw.githubusercontent.com/valda-z/IaaC/master/01-singlevm/install.sh"

```