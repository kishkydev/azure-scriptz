#Connect to Azure account
Connect-AzAccount
Write-Output -InputObject "Login successfully"

#Specify the Subscription in a multi-sub-environment
Set-AzContext -Subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Variables for common values
$RG= 'UNICORN-RG'
$location= 'northeurope'

# Create user object
$securePassword = ConvertTo-SecureString 'Wu26d-p$T?Q$d9^k^jsf4Lu' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("unicorn", $securePassword)

# Create a resource group.
New-AzResourceGroup -Name $RG -Location $location
Write-Output -InputObject "Resource Group UNICORN-RG created successfully"

# Create a virtual network with three subnets.
$WebSubnet = New-AzVirtualNetworkSubnetConfig -Name Web-Subnet -AddressPrefix '192.168.100.0/28'
$AppSubnet  = New-AzVirtualNetworkSubnetConfig -Name App-Subnet  -AddressPrefix '192.168.100.16/28'
$DbSubnet  = New-AzVirtualNetworkSubnetConfig -Name Db-Subnet  -AddressPrefix '192.168.100.32/28'
$vnet = New-AzVirtualNetwork -Name UNICORN-VNET -ResourceGroupName  $RG -Location $location -AddressPrefix '192.168.100.0/24' -Subnet $AppSubnet,$WebSubnet,$DbSubnet
Write-Output -InputObject "VNET UNICORN-VNET created successfully"

# Create an NSG rule to allow HTTP traffic in from the Internet to the Web-Subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP'`
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80
  
# Create an NSG rule to allow SSH traffic from the Internet to the Web-Subnet.
$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-SSH-All' -Description "Allow SSH" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 22

# Create a network security group for the Web-Subnet.
$nsgws = New-AzNetworkSecurityGroup -ResourceGroupName $RG -Location $location `
  -Name 'NSG-Web-Subnet' -SecurityRules $rule1,$rule2

# Associate the  NSG-Web-Subnet to the Web-Subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'Web-Subnet'-AddressPrefix '192.168.100.0/28' -NetworkSecurityGroup $nsgws


# Create an NSG rule to allow RDP traffic from the Internet to the App-Subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389

# Create a network security group for App-Subnet.
$nsgApps = New-AzNetworkSecurityGroup -ResourceGroupName $RG -Location $location `
  -Name "Nsg-App-Subnet" -SecurityRules $rule1

# Associate the Nsg-App-Subnet to the App-Subnet
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'App-Subnet' -AddressPrefix '192.168.100.16/28' -NetworkSecurityGroup $nsgApps

  # Create an NSG rule to allow SSH traffic from the Internet to the Db-Subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-SSH-All' -Description "Allow SSH" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 22

# Create a network security group for the Db-Subnet.
$nsgdbs = New-AzNetworkSecurityGroup -ResourceGroupName $RG -Location $location -Name 'NSG-Db-Subnet' -SecurityRules $rule1

# Associate the  NSG-Web-Subnet to the Db-Subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'Web-Subnet' -AddressPrefix '192.168.100.32/28' -NetworkSecurityGroup $nsgdbs

# Create a public IP address for the Unicorn-Web VM.
$webpip = New-AzPublicIpAddress -ResourceGroupName $RG -Name 'Web-PIP' -location $location -AllocationMethod Static -Sku Standard 

# Create a NIC for the Unicorn-Web VM.
$nicVMWeb = New-AzNetworkInterface -ResourceGroupName $RG -Location $location -Name 'Nic-Web' -PublicIpAddress $webpip  -NetworkSecurityGroup $nsgws -Subnet $vnet.Subnets[0]

###NB; get image details with az vm image list --publisher RedHat --all -o table#####

# Create Unicorn-App VM in the App-subnet.
# Create a NIC for the Unicorn-App VM.
$nicVmApp = New-AzNetworkInterface -ResourceGroupName $RG -Location $location -Name 'Nic-App'  -NetworkSecurityGroup $nsgApps -Subnet $vnet.Subnets[1]
# Create the VM configuration object

$VmName = "Unicorn-App"
$VmSize = "Standard_B1s"
$securePassword = ConvertTo-SecureString 'Wu26d-p$T?Q$d9^k^jsf4Lu' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("unicorn", $securePassword)
$nicVmApp =  Get-AzNetworkInterface -Name Nic-App
$VirtualMachine = New-AzVMConfig -VMName $VmName -VMSize $VmSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VmName -Credential $cred
$VirtualMachine = Set-AzVMSourceImage  -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version "latest" | Add-AzVMNetworkInterface -Id $nicVmApp.Id
# Create the VM
New-AzVM -ResourceGroupName $RG -Location $location -VM $VirtualMachine
Write-Output -InputObject "Unicorn-App created successfully"

# Create Unicorn-Web VM in the Web-subnet.
# Create the VM configuration object
$VmName = "Unicorn-web"
$VmSize = "Standard_B1s"
$nicVmweb =  Get-AzNetworkInterface -Name Nic-Web
$VirtualMachine = New-AzVMConfig -VMName $VmName -VMSize $VmSize

$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName "Unicorn-web" -Credential $cred

$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-focal" -Skus "20_04-lts-gen2" -Version "latest" |Add-AzVMNetworkInterface -Id $nicVmweb.Id

# Configure SSH keys
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

# Add the SSH key to the VM
Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/unicorn/.ssh/authorized_keys"

# Create the VM
New-AzVM -ResourceGroupName $RG -Location $location -VM $VirtualMachine

Write-Output -InputObject "Unicorn-Web created successfully"


# Create a NIC for the Unicorn-Db VM.
$nicVMDb = New-AzNetworkInterface -ResourceGroupName $RG -Location $location -Name 'Nic-Db'  -NetworkSecurityGroup $nsgws -Subnet $vnet.Subnets[2]

# Create Unicorn-Db VM in the Db-subnet.
# Create the VM configuration object
$VmName = "Unicorn-Db"
$VmSize = "Standard_B1s"
$nicVmweb =  Get-AzNetworkInterface -Name Nic-Db
$VirtualMachine = New-AzVMConfig -VMName $VmName -VMSize $VmSize

$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName "Unicorn-Db" -Credential $cred

$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName "RedHat" -Offer "RHEL" -Skus "82gen2" -Version "8.2.2021040912" |Add-AzVMNetworkInterface -Id $nicVmDb.Id

# Configure SSH keys
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

# Add the SSH key to the VM
Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/unicorn/.ssh/authorized_keys"

# Create the VM
New-AzVM -ResourceGroupName $RG -Location $location -VM $VirtualMachine
Write-Output -InputObject "Unicorn-Db created successfully"