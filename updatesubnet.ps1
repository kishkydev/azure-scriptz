 $VNET = Get-AzVirtualNetwork -Name Unicorn-VNET -ResourceGroupName Unicorn-RG
 Get-AzVirtualNetworkSubnetConfig -Name Felco-Subnet   -VirtualNetwork $VNET
 Set-AzVirtualNetworkSubnetConfig -Name  Felco-Subnet -VirtualNetwork $VNET -AddressPrefix "192.168.20.54/28"