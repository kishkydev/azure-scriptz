#!/bin/bash
### 1 Login to your Azure Account
az login --tenant      TenantID
#subscription="<subscriptionId>" # add subscription here
#az account set -s $subscription # ...or use 'az login'

#### 2 Declare common variables
loc="NorthEurope"
rg="Unicorn-RG"
ansg="app-nsg"
wnsg="web-nsg"
dnsg="db-nsg"
vnet="Unicorn-Vnet"
wsub="Web-Subnet"
asub="App-Subnet"
dsub="Db-Subnet"
vmWeb="Unicorn-Web"
vmApp="Unicorn-App"
vmDb="Unicorn-Db"
webPIP="Web-PIP"
nicWeb="NIC-Web"
nicApp="NIC-App"
nicDb="NIC-Db"
vmUser="unicorn"
$vmsize="Standard_B1S"
webimage="Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest"
appimage="MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest"
dbimage="RedHat:RHEL:82gen2:8.2.2021040912"
vmPassword="Bravotango@999"

### 3 Create Resource Group
az group create -l $loc -n $rg

### 4 Create a VNET With three Subnets
az network vnet create -g $rg -n $vnet --address-prefix 192.168.20.0/24 --subnet-name $wsub --subnet-prefix 192.168.20.0/28
az network vnet subnet create -n $asub --vnet-name  $vnet -g $rg  --address-prefixes 192.168.20.16/28
az network vnet subnet create -n $dsub --vnet-name  $vnet -g $rg  --address-prefixes 192.168.20.32/28

# 5 Create a network security group (NSG) for the Web-subnet.
az network nsg create --resource-group $rg --name $wnsg --location $loc

# Create NSG rules to allow HTTP, HTTPS & SSH traffic inbound.
az network nsg rule create --resource-group $rg --nsg-name $wnsg --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group $rg --nsg-name $wnsg --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443
az network nsg rule create --resource-group $rg --nsg-name $wnsg --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22

# 6 Create a network security group (NSG) for the App-subnet.
az network nsg create --resource-group $rg --name $ansg --location $loc

# 7 Create NSG rules to allow HTTP, HTTPS & RDP traffic inbound.
az network nsg rule create --resource-group $rg --nsg-name $ansg --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group $rg --nsg-name $ansg --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443
az network nsg rule create --resource-group $rg --nsg-name $ansg --name Allow-RDP-All --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 3389

# 8 Create a network security group (NSG) for the Db-subnet.
az network nsg create --resource-group $rg --name $dnsg --location $loc

# Create an NSG rule to allow SSH traffic inbound.
az network nsg rule create --resource-group $rg --nsg-name $dnsg --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22

# 9 Associate the WEB-NSG to the Web-Subnet.
az network vnet subnet update --vnet-name $vnet --name $wsub --resource-group $rg --network-security-group $wnsg

# 10 Associate the WEB-NSG to the App-Subnet.
az network vnet subnet update --vnet-name $vnet --name $asub --resource-group $rg --network-security-group $ansg

# 11 Associate the WEB-NSG to the Db-Subnet.
az network vnet subnet update --vnet-name $vnet --name $dsub --resource-group $rg --network-security-group $dnsg

# 12 Create a public IP address for the Unicorn-Web VM.
az network public-ip create --resource-group $rg --name $webPIP --sku Standard --allocation-method Static

# 13 Create a NIC for the Unicorn-Web VM.
az network nic create --resource-group $rg --name $nicWeb --vnet-name $vnet --subnet $wsub --network-security-group $wnsg --public-ip-address $webPIP

#  14 Create a NIC for the Unicorn-App VM.
az network nic create --resource-group $rg --name $nicApp --vnet-name $vnet --subnet $asub --network-security-group $ansg 

# 15 Create a NIC for the Unicorn-Db VM.
az network nic create --resource-group $rg --name $nicDb --vnet-name $vnet --subnet $dsub --network-security-group $dnsg 

#15 Create VM Unicorn-Web
az vm create --resource-group $rg --location $loc --name $vmWeb --nics $nicWeb --image $webimage --admin-username $vmUser --size $vmsize --admin-password $vmPassword

#16 Create VM Unicorn-App
az vm create --resource-group $rg --location $loc --name $vmApp --nics $nicApp --image $appimage --admin-username $vmUser --size $vmsize --admin-password $vmPassword

#17 Create VM Unicorn-Db
az vm create --resource-group $rg --location $loc --name $vmDb --nics $nicDb --image $dbimage --admin-username $vmUser --size $vmsize --admin-password $vmPassword


####References

##https://www.game.ahlikuncibekasi.net/use-azure-marketplace-image-to-create-vm-image-for-azure-stack-edge-pro-gpu-device/
###https://passwordsgenerator.net/
##https://docs.microsoft.com/en-us/azure-stack/user/azure-stack-quick-create-vm-linux-powershell?view=azs-2108&tabs=az1%2Caz2%2Caz3%2Caz4%2Caz5%2Caz6%2Caz7%2Caz8
##https://docs.ukcloud.com/articles/azure/azs-how-create-vm-cli.html
## https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-create
##https://docs.microsoft.com/en-us/azure/virtual-network/scripts/virtual-network-cli-sample-multi-tier-application
## az group delete -n $rg


