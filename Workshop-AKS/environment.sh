
subscription="cd690567-d725-4a00-95a6-d63e71d37064"
az account set --subscription $subscription
resourceGroup=$(az group create --location westeurope --resource-group rg-workshop -o tsv --query "name")
aksVnet="vnet-workshop"
appgwName="appgw-workshop"
appgwPublicIpName="appgw-workshop-ip"
string=$(($RANDOM % 1000))
aksacr=acrworkshop$string

az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights

#Vnet
az network vnet create \
  --name $aksVnet \
  --resource-group $resourceGroup \
  --address-prefix 10.214.0.0/16

#Subnets
az network vnet subnet create \
  --name appgwsubnet \
  --resource-group $resourceGroup \
  --vnet-name $aksVnet  \
  --address-prefix 10.214.1.0/24

  az network vnet subnet create \
  --name aksSubnet \
  --resource-group $resourceGroup \
  --vnet-name $aksVnet  \
  --address-prefix 10.214.2.0/24

    az network vnet subnet create \
  --name vmsSubnet \
  --resource-group $resourceGroup \
  --vnet-name $aksVnet  \
  --address-prefix 10.214.3.0/24

      az network vnet subnet create \
  --name AzureBastionSubnet \
  --resource-group $resourceGroup \
  --vnet-name $aksVnet  \
  --address-prefix 10.214.5.0/24

#ACR
  az acr create --resource-group $resourceGroup \
  --name $aksacr --sku Basic
#VM
az vm create \
    --resource-group $resourceGroup \
    --name vm-aks-workshop \
    --image Win2019Datacenter \
    --vnet-name $aksVnet \
    --subnet vmsSubnet \
    --public-ip-sku Standard \
    --public-ip-address "" \
    --admin-username azureadmin \
    --admin-password @-v3ry-53cr37-p455w0rd
#Bastion
  ##Bastion IP
az network public-ip create \
  --resource-group $resourceGroup\
  --name pip-bastion --sku Standard \
  --location westeurope
   ##Bastion Network
az network bastion create \
    --name NetworkBastion \
    --public-ip-address pip-bastion \
    --resource-group $resourceGroup \
    --vnet-name $aksVnet \
    --location westeurope \
    --subscription $subscription

#APPGW
az network application-gateway create \
  --name $appgwName \
  --location westeurope \
  --resource-group $resourceGroup \
  --vnet-name $aksVnet \
  --subnet appgwsubnet \
  --capacity 2 \
  --sku WAF_v2 \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --public-ip-address $appgwPublicIpName



  #AKS
az aks create \
--resource-group rg-workshop  \
--name aks-workshop \
--network-plugin azure  \
--network-policy azure  \
--vnet-subnet-id /subscriptions/$subscription/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$aksVnet/subnets/aksSubnet   \
--docker-bridge-address 172.17.0.1/16  \
--dns-service-ip 10.2.0.10  \
--service-cidr 10.2.0.0/24 \
--attach-acr $aksacr   \
--enable-managed-identity \
--generate-ssh-keys \
--yes  


