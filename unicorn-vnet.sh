#!/bin/bash
az login --tenant 9c922ccd-68b9-44ed-96c5-5234f6455404
az group create -l westeurope -n Unicorn-RG
az network vnet create -g Unicorn-RG -n Unicorn-Vnet --address-prefix 192.168.20.0/24 --subnet-name Frontend-Subnet --subnet-prefix 192.168.20.0/28
az network vnet subnet create -n Backend-Subnet --vnet-name  Unicorn-Vnet -g Unicorn-RG  --address-prefixes 192.168.20.16/28
az network vnet subnet create -n Db-Subnet --vnet-name  Unicorn-Vnet -g Unicorn-RG  --address-prefixes 192.168.20.32/28
az network vnet subnet create -n Bastion-Subnet --vnet-name  Unicorn-Vnet -g Unicorn-RG  --address-prefixes 192.168.20.48/28