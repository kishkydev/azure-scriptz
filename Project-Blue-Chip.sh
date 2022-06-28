#!/bin/bash
### 1 Login to your Azure Account
az login --tenant      TenantID
#subscription="<subscriptionId>" # add subscription here
#az account set -s $subscription # ...or use 'az login'

#### BERMUDA-SITE DEPLOYMENT
#### 2 Declare common variables
locB="NorthEurope"
rg="Project-Blue-Chip"
Bnsg="Bermuda-nsg"
vnetB="Bermuda-Site"
Bcsub="Client-Subnet"
Bssub="Server-Subnet"
vmBC="B-Client-VM"
vmBS="B-Server-VM"
vmBCPIP="B-Client-PIP"
vmBSPIP="B-Server-PIP"
nicBC="NIC-BC"
nicBS="NIC-BS"
vmUser="bermuda"
vmPassword="Bravotango@999"
vmsize="Standard_B1S"
clientimage="microsoftwindowsdesktop:windows-11:win11-21h2-pro:latest"
serverimage="RedHat:RHEL:82gen2:8.2.2021040912"

### 3 Create Resource Group
az group create -l $locB -n $rg

### 4 Create a VNET With two Subnets
az network vnet create -g $rg -n $vnetB --address-prefix 192.168.16.0/24 --subnet-name $Bcsub --subnet-prefix 192.168.16.0/28
az network vnet subnet create -n $Bssub --vnet-name  $vnetB -g $rg  --address-prefixes 192.168.16.16/28

# 5 Create a network security group (NSG) for Bermuda-Site
az network nsg create --resource-group $rg --name $Bnsg --location $locB


# Create NSG rules to allow HTTP, HTTPS,RDP & SSH traffic inbound.
az network nsg rule create --resource-group $rg --nsg-name $Bnsg --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group $rg --nsg-name $Bnsg --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443
az network nsg rule create --resource-group $rg --nsg-name $Bnsg --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22
az network nsg rule create --resource-group $rg --nsg-name $Bnsg --name Allow-RDP-All --access Allow --protocol Tcp --direction Inbound --priority 400 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 3389

# 9 Associate the Bermuda-nsg to the Client-Subnet and Server-Subnet.
az network vnet subnet update --vnet-name $vnetB --name $Bcsub --resource-group $rg --network-security-group $Bnsg
az network vnet subnet update --vnet-name $vnetB --name $Bssub --resource-group $rg --network-security-group $Bnsg

# 10 Create a public IP address for the B-Client-VM.
az network public-ip create --resource-group $rg --name $vmBCPIP --sku Standard --allocation-method Static

# 11 Create a NIC for the B-Client-VM .
az network nic create --resource-group $rg --name $nicBC --vnet-name $vnetB --subnet $Bcsub --network-security-group $Bnsg --public-ip-address $vmBCPIP


# 12 Create a public IP address for the B-Server-VM.
az network public-ip create --resource-group $rg --name $vmBSPIP --sku Standard --allocation-method Static

# 13 Create a NIC for the B-Server-VM .
az network nic create --resource-group $rg --name $nicBS --vnet-name $vnetB --subnet $Bssub --network-security-group $Bnsg --public-ip-address $vmBSPIP

#14 Create VM B-Client-VM
az vm create --resource-group $rg --location $locB --name $vmBC --nics $nicBC --image $clientimage --admin-username $vmUser --size $vmsize --admin-password $vmPassword

#15 Create VM B-Server-VM
az vm create --resource-group $rg --location $locB --name $vmBS --nics $nicBS --image $serverimage --admin-username $vmUser --size $vmsize --admin-password $vmPassword



#### CUBA-SITE DEPLOYMENT
####  Declare common variables
locC="westeurope"
rg="Project-Blue-Chip"
Cnsg="Cuba-nsg"
vnetC="Cuba-Site"
Ccsub="Client-Subnet"
Cssub="Server-Subnet"
vmCC="C-Client-VM"
vmCS="C-Server-VM"
vmCCPIP="C-Client-PIP"
vmCSPIP="C-Server-PIP"
nicCC="NIC-CC"
nicCS="NIC-CS"
vmUser="cuba"
vmPassword="Bravotango@999"
vmsize="Standard_B1S"
clientimage="microsoftwindowsdesktop:windows-11:win11-21h2-pro:latest"
serverimage="RedHat:RHEL:82gen2:8.2.2021040912"

### 1 Create a VNET With two Subnets
az network vnet create -g $rg -n $vnetC --address-prefix 172.30.60.0/24 --subnet-name $Ccsub --subnet-prefix 172.30.60.0/28 --location $locC
az network vnet subnet create -n $Cssub --vnet-name  $vnetC -g $rg  --address-prefixes 172.30.60.16/28

# 2 Create a network security group (NSG) for Cuba-Site
az network nsg create --resource-group $rg --name $Cnsg --location $locC


# Create NSG rules to allow HTTP, HTTPS,RDP & SSH traffic inbound.
az network nsg rule create --resource-group $rg --nsg-name $Cnsg --name Allow-HTTP-All --access Allow --protocol Tcp --direction Inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group $rg --nsg-name $Cnsg --name Allow-HTTPS-All --access Allow --protocol Tcp --direction Inbound --priority 200 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 443
az network nsg rule create --resource-group $rg --nsg-name $Cnsg --name Allow-SSH-All --access Allow --protocol Tcp --direction Inbound --priority 300 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22
az network nsg rule create --resource-group $rg --nsg-name $Cnsg --name Allow-RDP-All --access Allow --protocol Tcp --direction Inbound --priority 400 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 3389

# 3 Associate the Cuba-nsg to the Client-Subnet and Server-Subnet.
az network vnet subnet update --vnet-name $vnetC --name $Ccsub --resource-group $rg --network-security-group $Cnsg
az network vnet subnet update --vnet-name $vnetC --name $Cssub --resource-group $rg --network-security-group $Cnsg

# 4 Create a public IP address for the C-Client-VM.
az network public-ip create --resource-group $rg --name $vmCCPIP --sku Standard --allocation-method Static --location $locC

# 5 Create a NIC for the C-Client-VM .
az network nic create --resource-group $rg --name $nicCC --vnet-name $vnetC --subnet $Ccsub --network-security-group $Cnsg --public-ip-address $vmCCPIP --location $locC


# 6 Create a public IP address for the C-Server-VM.
az network public-ip create --resource-group $rg --name $vmCSPIP --sku Standard --allocation-method Static --location $locC

# 7 Create a NIC for the C-Server-VM .
az network nic create --resource-group $rg --name $nicCS --vnet-name $vnetC --subnet $Cssub --network-security-group $Cnsg --public-ip-address $vmCSPIP --location $locC

#8 Create VM C-Client-VM
az vm create --resource-group $rg --location $locC --name $vmCC --nics $nicCC --image $clientimage --admin-username $vmUser --size $vmsize --admin-password $vmPassword

#9 Create VM C-Server-VM
az vm create --resource-group $rg --location $locC --name $vmCS --nics $nicCS --image $serverimage --admin-username $vmUser --size $vmsize --admin-password $vmPassword

## az group delete -n $rg

