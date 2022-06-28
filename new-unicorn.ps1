# Connect to Azure Account
Connect-AzAccount


#Specify the Subscription in a multi-sub-environment
Set-AzContext -Subscription "4228efc4-a331-4fea-87d7-1adc8c67bd81"

# Variables for common values
$rg= "Unicorn-RG"
$loc= "northeurope"

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."
# Create a resource group.
New-AzResourceGroup -Name $rg -Location $loc

# Create a virtual network with three subnets
$ws = New-AzVirtualNetworkSubnetConfig -Name 'web-subnet' -AddressPrefix '192.168.100.0/28'
$as = New-AzVirtualNetworkSubnetConfig -Name 'app-subnet' -AddressPrefix '192.168.100.16/28'
$ds = New-AzVirtualNetworkSubnetConfig -Name 'db-subnet' -AddressPrefix '192.168.100.32/28'
$vnet = New-AzVirtualNetwork -ResourceGroupName $rg  -Name 'unicorn-vnet' -AddressPrefix '192.168.100.0/24' -Location $loc -Subnet $ws, $as, $ds

### CREATE NSG FOR WEB SUBNET AND ASSOCIATE IT WITH WEB SUBNET

# Create an NSG rule to allow HTTP traffic in from the Internet to the web subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

# Create an NSG rule to allow SSH traffic from the Internet to the web subnet.
$rule2 = New-AzNetworkSecurityRuleConfig -Name 'Allow-SSH-All' -Description "Allow SSH" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 22

# Create a network security group for the web subnet.
$wsNsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $loc `
  -Name 'Web-Sub-Nsg' -SecurityRules $rule1,$rule2

# Associate the web NSG to the web subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'web-subnet' `
  -AddressPrefix '192.168.100.0/28' -NetworkSecurityGroup $wsNsg

  ### CREATE NSG FOR APP SUBNET AND ASSOCIATE IT WITH APP SUBNET

# Create an NSG rule to allow RDP traffic in from the Internet to the APP subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description 'Allow RDP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389


# Create a network security group for the APP subnet.
$asNsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $loc `
  -Name 'APP-Sub-Nsg' -SecurityRules $rule1

# Associate the APP NSG to the APP subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'app-subnet' `
  -AddressPrefix '192.168.100.16/28' -NetworkSecurityGroup $asNsg

  ### CREATE NSG FOR DB SUBNET AND ASSOCIATE IT WITH DB SUBNET

# Create an NSG rule to allow SSH traffic in from the Internet to the DB subnet.
$rule1 = New-AzNetworkSecurityRuleConfig -Name 'Allow-SSH-All' -Description 'Allow SSH' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 22


# Create a network security group for the DB subnet.
$dsNsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Location $loc `
  -Name 'DB-Sub-Nsg' -SecurityRules $rule1

# Associate the DB NSG to the DB subnet.
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'DB-subnet' `
  -AddressPrefix '192.168.100.32/28' -NetworkSecurityGroup $dsNsg

  # Create a public IP address for the web server VM.
$webPIP = New-AzPublicIpAddress -ResourceGroupName $rg -Name 'Web-PIP' `
  -location $loc -AllocationMethod Static -Sku Standard

  # Create a NIC for the web server VM.
$nicVMweb = New-AzNetworkInterface -ResourceGroupName $rg -Location $loc `
  -Name 'Nic-Web' -PublicIpAddress $webPIP -NetworkSecurityGroup $wsNsg -Subnet $vnet.Subnets[0]

$VmName = "Unicorn-web"
$VmSize = "Standard_B1s"
$nicVMweb =  Get-AzNetworkInterface -Name Nic-Web
$VirtualMachine = New-AzVMConfig -VMName $VmName -VMSize $VmSize

$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName "Unicorn-web" -Credential $cred -DisablePasswordAuthentication 

$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-focal" -Skus "20_04-lts-gen2" -Version "latest" |Add-AzVMNetworkInterface -Id $nicVMweb.Id

# Configure SSH keys
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

# Add the SSH key to the VM
Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/unicorn/.ssh/authorized_keys"
# Create the VM
New-AzVM -ResourceGroupName $RG -Location $loc -VM $VirtualMachine

# Create a NIC for the App server VM.
$nicVMapp = New-AzNetworkInterface -ResourceGroupName $rg -Location $loc `
  -Name 'Nic-App'  -NetworkSecurityGroup $asNsg -Subnet $vnet.Subnets[1]

$VmName = "Unicorn-App"
$VmSize = "Standard_B1s"
$nicVmApp =  Get-AzNetworkInterface -Name Nic-App
$VirtualMachine = New-AzVMConfig -VMName $VmName -VMSize $VmSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VmName -Credential $cred
$VirtualMachine = Set-AzVMSourceImage  -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version "latest" | Add-AzVMNetworkInterface -Id $nicVmApp.Id
# Create the VM
New-AzVM -ResourceGroupName $RG -Location $loc -VM $VirtualMachine

# Create a NIC for the Db server VM.
$nicVMdb = New-AzNetworkInterface -ResourceGroupName $rg -Location $loc `
  -Name 'Nic-Db'  -NetworkSecurityGroup $dsNsg -Subnet $vnet.Subnets[2]

$VmName = "Unicorn-Db"
$VmSize = "Standard_B1s"
$nicVmweb =  Get-AzNetworkInterface -Name Nic-Db
$VirtualMachine = New-AzVMConfig -VMName $VmName -VMSize $VmSize

$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName "Unicorn-Db" -Credential $cred

$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName "RedHat" -Offer "RHEL" -Skus "82gen2" -Version "8.2.2021040912" |Add-AzVMNetworkInterface -Id $nicVMdb.Id

# Configure SSH keys
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

# Add the SSH key to the VM
Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/unicorn/.ssh/authorized_keys"

# Create the VM
New-AzVM -ResourceGroupName $RG -Location $loc -VM $VirtualMachine

### Remove-AzResourceGroup -Name $rg###