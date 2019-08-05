#!/bin/bash

git clone https://github.com/kubernauts/aks-terraform-rancher && cd aks-terraform-rancher

az group create --name aks-dev-test-rg --location northeurope

az group deployment create --name k8s-dev-test-deployment --resource-group aks-dev-test-rg --template-file template.json —parameters parameters.json

az ad sp create-for-rbac --skip-assignment

az network vnet subnet list — resource-group dev-test-rg — vnet-name dev-test-vnet — query [].id — output tsv

az aks create \

source create-azure-storage-account.sh northeurope storage-account-rg acemesa tfstate

az group create --name key-vault-rg --location northeurope

az keyvault create --name “aceme-aks-key-vault” --resource-group “key-vault-rg” --location “northeurope”

    az keyvault secret set --vault-name “aceme-aks-key-vault” --name “terraform-backend-key” --value <the value of the access_key key1>

az keyvault secret show --name terraform-backend-key --vault-name aceme-aks-key-vault --query value -o tsv

export ARM_ACCESS_KEY=$(az keyvault secret show --name terraform-backend-key --vault-name aceme-aks-key-vault — query value -o tsv)

echo $ARM_ACCESS_KEY

terraform init -backend-config=”storage_account_name=acemesa” -backend-config=”container_name=tfstate” -backend-config=”key=aceme-management.tfstate”

./createTerraformServicePrincipal.sh

./create-azure-ad-server-app.sh

source create-azure-ad-client-app.sh

export ARM_ACCESS_KEY=$(az keyvault secret show --name terraform-backend-key --vault-name aceme-aks-key-vault --query value -o tsv)

source export_tf_vars

terraform plan -out rancher-management-plan

terraform apply rancher-management-plan -auto-approve

az aks get-credentials -n CLUSTER_NAME -g RESOURCE_GROUP_NAME — admin

az aks get-credentials -n k8s-pre-prod -g kafka-pre-prod-rg — admin

k get nodes

kubectl apply -f cluster-admin-rolebinding.yaml

az aks get credentials -n CLUSTER_NAME -g RESOURCE_GROUP_NAME

kubectl get nodes

az group create --name aceme-dev-test-rg --location northeurope

terraform init -backend-config=”storage_account_name=acemesa” -backend-config=”container_name=tfstate” -backend-config=”key=aceme-dev-test.tfstate”

terraform plan -var resource_group_name=aceme-dev-test-rg -var aks_name=aceme-kafka-dev-test -out aceme-kafka-dev-test-plan

terraform apply aceme-kafka-dev-test-plan -auto-approve

az keyvault secret show --name rancher-aad-secret --vault-name aceme-aks-key-vault --query value -o tsv

terraform output kube_config | grep clusterUser

    kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user <provide the user from command above>

curl --insecure -sfL [https://aceme-rancher-ingress.northeurope.cloudapp.azure.com/v3/import/xyz.yaml](https://aceme-rancher-ingress.northeurope.cloudapp.azure.com/v3/import/xyz.yaml) | kubectl apply -f -

terraform destroy -var resource_group_name=aceme-kafka-pre-prod-rg -var aks_name=kafka-pre-prod

kubectl get componentstatus

cat delete-cattle-system-ns
