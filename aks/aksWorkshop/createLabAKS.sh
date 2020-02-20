az login
SUB_ID=""
REGION=""
RG_NAME=""
AKS_CLUSTER=""
AKS_SPN=""
AD_APP_NAME=""

az account set --subscription ${SUB_ID}
az ad app create --display-name ${AD_APP_NAME} --homepage "http://localhost/${AD_APP_NAME}" --identifier-uris [http://localhost/${AD_APP_NAME}](http://localhost/${AD_APP_NAME})
AD_APP_ID=$(az ad app list --display-name ${AD_APP_NAME} --query [].appId -o tsv)
SPN_PASSWORD="blahfishpaste"
az ad sp create-for-rbac --name ${AD_APP_NAME} --password ${SPN_PASSWORD}

az aks get-versions -l ${REGION} -o table
kubernetesVersionLatest=$(az aks get-versions -l ${REGION} --query 'orchestrators[-1].orchestratorVersion' -o tsv)

az ad sp create-for-rbac --name ${AKS_SPN} --output table
AKS_APP_ID=$(az ad app list --display-name ${AKS_SPN} --query [].appId -o tsv)
az group create --name ${RG_NAME} --location ${REGION}
kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
az aks create --resource-group akschallenge --name ${AKS_CLUSTER}--enable-addons monitoring --kubernetes-version $kubernetesVersionLatest --generate-ssh-keys --location ${REGION} --service-principal ${AD_APP_ID} --client-secret ${SPN_PASSWORD}
#az aks create --resource-group ${RG_NAME} --name ${AKS_CLUSTER} --enable-addons monitoring --generate-ssh-keys --location ${REGION} --kubernetes-version $kubernetesVersionLatest
az aks install-cli 
az aks get-credentials --resource-group ${RG_NAME} --name ${AKS_CLUSTER}
kubectl get nodes
