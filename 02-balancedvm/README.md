# Balanced set of VMs with PostgreSQL

Deploying set of VMs with load balancer, VMs will be installed automatically by extension script. 

Installation requires prepared RPM package stored somewhere - in our case we are using Azure blob storage.

Script will deploy:

* Linux (CentOS) based VMs with private IP address and Network Security Group enables communication to ports 8080 
* PostgreSQL database as service
* automatically install and configure our simple JAVA app to run as a system service in CentOS (script `install.sh` is used for installation)
* Load balancer with public IP address and balancing rule which sends communication from public IP address (port 80) to VMs internal IP addresses (port 8080)

Final architecture picture:
![](arch.png)

```bash
# go to directory with our experiment
cd 02-balancedvm
```

```bash
export RG=TST_02
export LOCATION=northeurope

# create resource group
az group create --location ${LOCATION} --name ${RG}

# run deployment
az group deployment create -g ${RG} --template-file azuredeploy.json --parameters \
    username="valda" \
    sshkey="$(cat ~/.ssh/id_rsa.pub)" \
    vmcount="3" \
    postgrename="valdatst02" \
    postgreuser="valda" \
    postgrepassword="pwd123..." \
    rpmurl="${RPM}" \
    artifactsLocation="https://raw.githubusercontent.com/valda-z/IaaC/master/02-balancedvm/install.sh"

```

Now you can use Azure portal and navigate to your Resource group, on the `load balancer` resource you can grab public IP address and try to connect to our JAVA web application on standard http port 80.
`http://<YOUR_IP_ADDRESS>`