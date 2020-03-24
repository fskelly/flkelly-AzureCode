az login
SUB_ID="949ef534-07f5-4138-8b79-aae16a71310c"
REGION="westeurope"
RG_NAME="flkelly-weu-rg1"
AKS_CLUSTER="flkelly-weu-rg1-aks"
AKS_SPN="aksspn-fl2"
AD_APP_NAME="aksapp02"

az account set --subscription ${SUB_ID}

az aks get-versions -l ${REGION} -o table
kubernetesVersionLatest=$(az aks get-versions -l ${REGION} --query 'orchestrators[-1].orchestratorVersion' -o tsv)

SPN=$(az ad sp create-for-rbac --name ${AKS_SPN})
AKS_APP_ID=$(az ad app list --display-name ${AKS_SPN} --query [].appId -o tsv)

##needed to get SPN PWD
sudo apt-get install jq

SPN_PWD=$(echo "${SPN}" | jq -c '.password')
SPN_PWD=$(echo ${SPN_PWD%?} | cut -c2-)

az group create --name ${RG_NAME} --location ${REGION}
#Please pick one, NOT BOTH autoscaler OR no autoscaler
#no autoscaler - 
az aks create --resource-group ${RG_NAME} --name ${AKS_CLUSTER} --enable-addons monitoring --kubernetes-version $kubernetesVersionLatest --generate-ssh-keys --location ${REGION} --service-principal ${AKS_APP_ID} --client-secret ${SPN_PWD}
#autoscaler
az aks create --resource-group ${RG_NAME} --name ${AKS_CLUSTER} --location ${REGION} --kubernetes-version $kubernetesVersionLatest --generate-ssh-keys --vm-set-type VirtualMachineScaleSets --enable-cluster-autoscaler --min-count 1 --max-count 3 --service-principal ${AKS_APP_ID} --client-secret ${SPN_PWD} --enable-monitoring


az aks install-cli 
az aks get-credentials --resource-group ${RG_NAME} --name ${AKS_CLUSTER}
kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
kubectl get nodes
az aks browse --resource-group ${RG_NAME} --name ${AKS_CLUSTER}