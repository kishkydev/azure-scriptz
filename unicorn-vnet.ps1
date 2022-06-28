Connect-AzAccount -TenantId "9c922ccd-68b9-44ed-96c5-5234f6455404"
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
New-AzResourceGroup -Name Unicorn-RG -Location northeurope
$frontendSubnet = New-AzVirtualNetworkSubnetConfig -Name Frontend-Subnet -AddressPrefix "192.168.20.0/28"
$backendSubnet  = New-AzVirtualNetworkSubnetConfig -Name Backend-Subnet  -AddressPrefix "192.168.20.16/28"
$DbSubnet  = New-AzVirtualNetworkSubnetConfig -Name Db-Subnet  -AddressPrefix "192.168.20.32/28"
$FelcoSubnet  = New-AzVirtualNetworkSubnetConfig -Name Felco-Subnet  -AddressPrefix "192.168.20.48/28"
New-AzVirtualNetwork -Name Unicorn-VNET -ResourceGroupName Unicorn-RG -Location northeurope -AddressPrefix "192.168.20.0/24" -Subnet $frontendSubnet,$backendSubnet,$DbSubnet,$FelcoSubnet