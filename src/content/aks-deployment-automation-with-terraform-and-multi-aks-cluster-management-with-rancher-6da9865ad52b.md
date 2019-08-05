* * *

# AKS Deployment Automation with Terraform and Multi-AKS Cluster Management with Rancher, AAD Integration and more

[![Go to the profile of Arash Kaffamanesh](https://cdn-images-1.medium.com/fit/c/100/100/1*stBhz2iQF4HcM-6hTZJVUg.jpeg)](https://blog.kubernauts.io/@kubernauts?source=post_header_lockup)[Arash Kaffamanesh](https://blog.kubernauts.io/@kubernauts)<span class="followState js-followState" data-user-id="d6c3d29f67f8"><button class="button button--smallest u-noUserSelect button--withChrome u-baseColor--buttonNormal button--withHover button--unblock js-unblockButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-block-user" data-requires-token="true" data-redirect="https://blog.kubernauts.io/aks-deployment-automation-with-terraform-and-multi-aks-cluster-management-with-rancher-6da9865ad52b" data-action-source="post_header_lockup"><span class="button-label  button-defaultState">Blocked</span><span class="button-label button-hoverState">Unblock</span></button><button class="button button--primary button--smallest button--dark u-noUserSelect button--withChrome u-accentColor--buttonDark button--follow js-followButton u-marginLeft10 u-xs-hide" data-action="sign-up-prompt" data-sign-in-action="toggle-subscribe-user" data-requires-token="true" data-redirect="https://medium.com/_/subscribe/user/d6c3d29f67f8" data-action-source="post_header_lockup-d6c3d29f67f8-------------------------follow_byline"><span class="button-label  button-defaultState js-buttonLabel">Follow</span><span class="button-label button-activeState">Following</span></button></span><time datetime="2019-03-16T22:43:52.863Z">Mar 16</time><span class="middotDivider u-fontSize12"></span><span class="readingTime" title="13 min read"></span><span class="u-paddingLeft4"><span class="svgIcon svgIcon--star svgIcon--15px"></span></span>![](https://cdn-images-1.medium.com/max/1600/1*yoKwOEyo_NocVFPWroiXLQ.png)

### Introduction

In one of our running Kubernetes projects, we have to deploy 10+ k8s clusters for running business critical apps and let these apps to talk to each other and allow access from on-prem external k8s clusters to them.

Due to some strategic decisions the project owners decided to give Azure Kubernetes Service a try and manage all AKS clusters through a Rancher Management Server Cluster running on an AKS made k8s cluster itself or on Rancher Kubernetes Engine RKE.

Running Rancher Management Server on RKE is our favourite option and highly recommended to use in long term. For our daily k8s development with Rancher, we’re running RKE on top of RancherOS on Bare-Metal servers with Metal-LB, which is our most stable and affordable solution so far.

But for now let’s not to talk about political decisions, but more about AKS deployment automation with terraform and run Rancher Management Server on top of AKS to manage other AKS or RKE clusters and integrate the whole thing with AAD (Azure Active Directory) and make use of Azure Storage to manage state for our teams.

At this time of writing, there are at least 5 approaches to deploy managed Kubernetes Clusters through Azure Kubernetes Service AKS, via Azure Portal, with CLI, with ARM Templates or Terraform scripts and additional modules or via Rancher Management Server itself.

In this first post I’m going to share all these options with a detailed implementation for AKS with our favourite DevOps tool **Terraform** from the awesome folks by HashiCorp and use Rancher to manage access via Azure Active Directory (AAD) for our users and do much more exciting things with Rancher and TK8 in the next blog post, which will be about how to deploy RKE with TK8 and Terraform in a Custom VNET with Kubenet on Azure.

### Sources on Github

All sources are provided on Github:

<pre name="3675" id="3675" class="graf graf--pre graf-after--p">$
git clone [https://github.com/kubernauts/aks-terraform-rancher.git](https://github.com/kubernauts/aks-terraform-rancher.git)</pre>

### Prerequisites

[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
[Terraform](https://www.terraform.io/downloads.html)

### Deployment via Azure Portal

This is the easiest deployment method, on Azure find the Kubernetes Service, click add, select a subscription, an existing resource group, or create a new one, select the k8s version, etc.. and click, click, click, then create, your AKS made k8s cluster is deployed in about 10 minutes, awesome!

You can download the ARM template-file template.json which is used in background for the AKS deployment through Azure Portal in the last step and create the deployment via CLI with ARM template-file “template.json” and “parameters.json” file as follow.

### Deployment with ARM Template

Create a resource group with az tool:

<pre name="6518" id="6518" class="graf graf--pre graf-after--p">$
az group create --name aks-dev-test-rg --location westeurope</pre>

Deploy AKS in the resource group created above:

<pre name="7a39" id="7a39" class="graf graf--pre graf-after--p">$
az group deployment create --name k8s-dev-test-deployment --resource-group aks-dev-test-rg --template-file template.json — parameters parameters.json</pre>

### Deployment with CLI

To deploy with CLI, you may use an existing [Azure Active Directory Service Principal](https://docs.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest) or create a new one for the deployment with az tool. AAD Service Principals are used for automation authentication for the deployment. With the following command we’ll create a new service principal and skip creating the default assignment, which allows the service principal to access resources under the current subscription.

<pre name="0cce" id="0cce" class="graf graf--pre graf-after--p">$
az ad sp create-for-rbac — skip-assignment</pre>

<pre name="6414" id="6414" class="graf graf--pre graf-after--pre">{</pre>

<pre name="b012" id="b012" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“appId”: “xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz”, → — service-principal</pre>

<pre name="4e96" id="4e96" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“displayName”: “azure-cli-2019–02–23–11-xyz”,</pre>

<pre name="3319" id="3319" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“name”: “[http://azure-cli-2019-02-23-11-31-36](http://azure-cli-2019-02-23-11-31-36)",</pre>

<pre name="7dd1" id="7dd1" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“password”: “xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz”, → — client-secret</pre>

<pre name="2f05" id="2f05" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“tenant”: “xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz”</pre>

<pre name="35e7" id="35e7" class="graf graf--pre graf-after--pre">}</pre>

The following az aks create command, creates an AKS 3 node cluster in an existing vnet. To find the id of an existing vnet, use the following command:

<pre name="fbba" id="fbba" class="graf graf--pre graf-after--p">$
az network vnet subnet list — resource-group dev-test-rg — vnet-name dev-test-vnet — query [].id — output tsv</pre>

Create the AKS cluster with CLI:

<pre name="c538" id="c538" class="graf graf--pre graf-after--p">$
az aks create \</pre>

<pre name="6f92" id="6f92" class="graf graf--pre graf-after--pre"> — resource-group xyz-rg \</pre>

<pre name="0bd1" id="0bd1" class="graf graf--pre graf-after--pre"> — name k8s-dev-test \</pre>

<pre name="c891" id="c891" class="graf graf--pre graf-after--pre"> — service-principal xyz \</pre>

<pre name="3312" id="3312" class="graf graf--pre graf-after--pre"> — client-secret xyz \</pre>

<pre name="edd6" id="edd6" class="graf graf--pre graf-after--pre"> — node-count 3 \</pre>

<pre name="b0b6" id="b0b6" class="graf graf--pre graf-after--pre"> — generate-ssh-keys \</pre>

<pre name="0eb4" id="0eb4" class="graf graf--pre graf-after--pre"> — nodepool-name devpool \</pre>

<pre name="583f" id="583f" class="graf graf--pre graf-after--pre"> — node-vm-size Standard_DS2_v2 \</pre>

<pre name="78f8" id="78f8" class="graf graf--pre graf-after--pre"> — service-cidr 10.0.0.0/16 \</pre>

<pre name="b896" id="b896" class="graf graf--pre graf-after--pre"> — network-plugin azure \</pre>

<pre name="7a35" id="7a35" class="graf graf--pre graf-after--pre"> — vnet-subnet-id /subscriptions/xyz/resourceGroups/xyz-rg/providers/Microsoft.Network/virtualNetworks/xyz-vnet/subnets/xyz-subnet \</pre>

<pre name="9f48" id="9f48" class="graf graf--pre graf-after--pre"> — tags environment=dev-test \</pre>

<pre name="ba18" id="ba18" class="graf graf--pre graf-after--pre"> — enable-addons monitoring \</pre>

<pre name="a66e" id="a66e" class="graf graf--pre graf-after--pre"> — docker-bridge-address 172.17.0.1/16</pre>

### AKS Deployment Automation with Terraform, the hard, but the right way

The deployment methods mentioned above are great for rapid deployments through a single user, but if you need to have full control of the AKS cluster state through your DevOps teams and apply the Infrastructure as Code (IaC) principle with GitOps and DevSecOps culture in mind, you may consider this implementation. [Kari Marttila](https://medium.com/@kari.marttila) explains in this nice post [”Creating Azure Kubernetes Service the right way](https://medium.com/@kari.marttila/creating-azure-kubernetes-service-aks-the-right-way-9b18c665a6fa)” why terraform is the better choice for humans!

The main goals for this implementation was:

*   Use Azure Storage Account to manage terraform state for teams
*   Use Azure Key Vault or HashiCorp Vault to retrieve secrets and keys for higher security
*   Use a custom terraform role and service principal for deployment (least privilege)
*   Use Azure Active Directory and deploy an RBAC-enabled AKS Cluster
*   Use Rancher Management Server to manage multiple AKS clusters and govern access to users through Azure Active Directory integration
*   Rancher Management Server shall run in HA mode on AKS cluster itself
*   If Rancher Management Server is not used or becomes unavailable, DevOps teams shall still be able to access the clusters managed by Rancher
*   Use [Terragrunt](https://github.com/gruntwork-io/terragrunt) and Git for terraform code changes and extensions through different DevOps teams (not in the repo yet)

### Create a Storage Account to manage terraform state for different clusters

Create in westeurope region a new resource groupe storage-account-rg and in this resource group create a storage account named “acemesa” with a container named tfstate:

<pre name="b71c" id="b71c" class="graf graf--pre graf-after--p">$
source create-azure-storage-account.sh westeurope storage-account-rg acemesa tfstate</pre>

The output of the command provides the access_key of the storage account, please take a note of the access_key of the storage account, or head to the azure portal and copy the key1 value of the “acemesa” storage account. We’ll store this access key in azure vault as “terraform-backend-key” in the next step after creating the key vault in a new resource group.

### Create Azure Key Vault

Create a resource group named “key-vault-rg”:

<pre name="5cc7" id="5cc7" class="graf graf--pre graf-after--p">$
az group create --name key-vault-rg --location westeurope</pre>

Create an azure key vault in this resource group:

<pre name="115b" id="115b" class="graf graf--pre graf-after--p">$
az keyvault create --name “aceme-aks-key-vault” --resource-group “key-vault-rg” --location “westeurope”</pre>

Create a new secret named “terraform-backend-key” in the key vault with the value of the storage access key created above:

<pre name="c37a" id="c37a" class="graf graf--pre graf-after--p">$
    az keyvault secret set --vault-name “aceme-aks-key-vault” --name “terraform-backend-key” --value <the value of the access_key key1></pre>

Verify if you can read the value of the created secret “terraform-backend-key”:

<pre name="a740" id="a740" class="graf graf--pre graf-after--p">$
az keyvault secret show --name terraform-backend-key --vault-name aceme-aks-key-vault --query value -o tsv</pre>

Export the environment variable “ARM_ACCESS_KEY”, to be able to initialise terraform with the storage account backend:

<pre name="7d0a" id="7d0a" class="graf graf--pre graf-after--p">$
export ARM_ACCESS_KEY=$(az keyvault secret show --name terraform-backend-key --vault-name aceme-aks-key-vault — query value -o tsv)</pre>

Verify if the access key has been exported properly:

<pre name="21bd" id="21bd" class="graf graf--pre graf-after--p">$
echo $ARM_ACCESS_KEY</pre>

### Initialise terraform for AKS deployment

Initialise Terraform with the storage account as backend to store “aceme-management.tfstate” in the container “tfsate” created in the first step above:

<pre name="337b" id="337b" class="graf graf--pre graf-after--p">$
terraform init -backend-config=”storage_account_name=acemesa” -backend-config=”container_name=tfstate” -backend-config=”key=aceme-management.tfstate”</pre>

With this we make sure that all team members can use the same terraform state file stored in azure storage account, to learn more about it, please head to [azure storage and terraform](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend) documentation on azure portal.

### Create a custom terraform service principal with least privilege to perform the AKS deployment

Execute the following [createTerraformServicePrincipal.sh](https://github.com/azurecitadel/azurecitadel.github.io/blob/master/automation/terraform/createTerraformServicePrincipal.sh) script provided by [Richard Cheney](https://twitter.com/RichCheneyAzure) to create the terraform service principal and the provider.tf file (the script is provided in the git repo as well):

The script will interactively:

*   Create the service principal (or resets the credentials if it already exists)
*   Prompts to choose either a populated or empty provider.tf azurerm provider block
*   Exports the environment variables if you selected an empty block (and display the commands)
*   Display the az login command to log in as the service principal

<pre name="1932" id="1932" class="graf graf--pre graf-after--li">$
./createTerraformServicePrincipal.sh</pre>

The output will be similar to this:

<pre name="ecca" id="ecca" class="graf graf--pre graf-after--p">{</pre>

<pre name="d3e9" id="d3e9" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“appId”: “xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz”,</pre>

<pre name="51b8" id="51b8" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“displayName”: “terraform-xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz”,</pre>

<pre name="65ca" id="65ca" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“name”: “http://terraform-xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz",</pre>

<pre name="28e6" id="28e6" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“password”: “xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz”,</pre>

<pre name="9618" id="9618" class="graf graf--pre graf--startsWithDoubleQuote graf-after--pre">“tenant”: “xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz”</pre>

<pre name="8b50" id="8b50" class="graf graf--pre graf-after--pre">}</pre>

Create a file named e.g. export_tf_vars and provide the TF_VAR_client_id with the value of “appId” and TF_VAR_client_secret with the value of “password” from the service principal output above, your export_tf_vars file should contain the following 2 lines for now. We need to extend it later after creating the server and client applications in the next steps.

<pre name="1702" id="1702" class="graf graf--pre graf-after--p">export TF_VAR_client_id=xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz
export TF_VAR_client_secret=xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz</pre>

For security reasons, make sure to store the client id and secret in azure key vault:

<pre name="5b5d" id="5b5d" class="graf graf--pre graf-after--p">az keyvault secret set --vault-name “aceme-aks-key-vault” --name “TF-VAR-client-id” --value xyz</pre>

<pre name="cfe4" id="cfe4" class="graf graf--pre graf-after--pre">az keyvault secret set --vault-name “aceme-aks-key-vault” --name “TF-VAR-client-secret” --value xyz</pre>

N.B.: we’ll use these values from the commands above in export_tf_vars file later!

### Azure Active Directory Authorization

To secure an AKS cluster with Azure Active Directory and RBAC, this [nice implementation](https://github.com/jcorioland/aks-rbac-azure-ad) from [Julien Corioland](https://github.com/jcorioland) was used.

In short, in order to enable Azure Active Directory authorization with Kubernetes, you need to create two applications:

*   A server application, that will work with Azure Active Directory
*   A client application, that will work with the server application

Multiple AKS clusters can use the same server application, but it’s recommended to have one client application per cluster.

Open the server application creation script create-azure-ad-server-app.sh and update the environment variables with the values you want to use:

<pre name="0fe0" id="0fe0" class="graf graf--pre graf-after--p">export RBAC_AZURE_TENANT_ID=”REPLACE_WITH_YOUR_TENANT_ID”
export RBAC_SERVER_APP_NAME=”AKSAADServer2"
export RBAC_SERVER_APP_URL=”[http://aksaadserver2](http://aksaadserver2)"
# on mac doesn’t work, on linux?</pre>

<pre name="adf4" id="adf4" class="graf graf--pre graf-after--pre"># export RBAC_SERVER_APP_SECRET=”$(cat /dev/urandom | tr -dc ‘a-zA-Z0–9’ | fold -w 32 | head -n 1)”
# on mac
export RBAC_SERVER_APP_SECRET=”$(LC_CTYPE=C tr -dc A-Za-z0–9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 32 | xargs)”</pre>

Execute the script:

<pre name="81b6" id="81b6" class="graf graf--pre graf-after--p">$
./create-azure-ad-server-app.sh</pre>

Once created you need to ask an Azure AD Administrator to go to the Azure portal and click the Grant permission button for this server app (Active Directory → App registrations (preview) → All applications → AKSAADServer2) .

![](https://cdn-images-1.medium.com/max/1600/0*ZEa-y4-UNllOYcYQ)

Click on AKSAADServer2 application → Api permissions → Grant admin consent

![](https://cdn-images-1.medium.com/max/1600/0*RRpx0wVQg10KY36a)

Copy the following environment variables to the client application creation script:

<pre name="c18a" id="c18a" class="graf graf--pre graf-after--p">export RBAC_SERVER_APP_ID=xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz</pre>

<pre name="ccc9" id="ccc9" class="graf graf--pre graf-after--pre">export RBAC_SERVER_APP_OAUTH2PERMISSIONS_ID=xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz</pre>

<pre name="befd" id="befd" class="graf graf--pre graf-after--pre">export RBAC_SERVER_APP_SECRET=xyzxyzxyzxyzxyzxyzxyzxyzxyzxyz</pre>

And execute / source the script:

<pre name="a758" id="a758" class="graf graf--pre graf-after--p">$
source create-azure-ad-client-app.sh</pre>

For security reasons you may want to store all values in azure key vault:

<pre name="8329" id="8329" class="graf graf--pre graf-after--p">az keyvault secret set — vault-name “aceme-aks-key-vault” — name “TF-VAR-rbac-server-app-id” — value xyz</pre>

<pre name="64d9" id="64d9" class="graf graf--pre graf-after--pre">az keyvault secret set — vault-name “aceme-aks-key-vault” — name “TF-VAR-rbac-server-app-secret” — value xyz</pre>

<pre name="3c7d" id="3c7d" class="graf graf--pre graf-after--pre">az keyvault secret set — vault-name “aceme-aks-key-vault” — name “TF-VAR-rbac-client-app-id” — value xyz</pre>

<pre name="b7a6" id="b7a6" class="graf graf--pre graf-after--pre">az keyvault secret set — vault-name “aceme-aks-key-vault” — name “TF-VAR-tenant-id” — value xyz</pre>

Your export_tf_vars looks like this at the end (this file is provided in the git repo):

<pre name="dd5b" id="dd5b" class="graf graf--pre graf-after--p">export TF_VAR_client_id=$(az keyvault secret show — name TF-VAR-client-id — vault-name aceme-aks-key-vault — query value -o tsv)</pre>

<pre name="a56b" id="a56b" class="graf graf--pre graf-after--pre">export TF_VAR_client_secret=$(az keyvault secret show — name TF-VAR-client-secret — vault-name aceme-aks-key-vault — query value -o tsv)</pre>

<pre name="82c4" id="82c4" class="graf graf--pre graf-after--pre">export TF_VAR_rbac_server_app_id=$(az keyvault secret show — name TF-VAR-rbac-server-app-id — vault-name aceme-aks-key-vault — query value -o tsv)</pre>

<pre name="85a5" id="85a5" class="graf graf--pre graf-after--pre">export TF_VAR_rbac_server_app_secret=$(az keyvault secret show — name TF-VAR-rbac-server-app-secret — vault-name aceme-aks-key-vault — query value -o tsv)</pre>

<pre name="d0b1" id="d0b1" class="graf graf--pre graf-after--pre">export TF_VAR_rbac_client_app_id=$(az keyvault secret show — name TF-VAR-rbac-client-app-id — vault-name aceme-aks-key-vault — query value -o tsv)</pre>

<pre name="e7ef" id="e7ef" class="graf graf--pre graf-after--pre">export TF_VAR_tenant_id=$(az keyvault secret show — name TF-VAR-tenant-id — vault-name aceme-aks-key-vault — query value -o tsv)</pre>

**Deploy AKS**

Now you can harvest your hard work by creating a plan for your first management cluster and apply it to create your first AKS made k8s cluster:

<pre name="614c" id="614c" class="graf graf--pre graf-after--p">$
export ARM_ACCESS_KEY=$(az keyvault secret show --name terraform-backend-key --vault-name aceme-aks-key-vault --query value -o tsv)</pre>

<pre name="7f0e" id="7f0e" class="graf graf--pre graf-after--pre">$
source export_tf_vars</pre>

<pre name="6301" id="6301" class="graf graf--pre graf-after--pre">$
terraform plan -out rancher-management-plan</pre>

<pre name="2ded" id="2ded" class="graf graf--pre graf-after--pre">$
terraform apply rancher-management-plan -auto-approve</pre>

**Configure RBAC**

After the cluster is deployed, we need to create Role/RoleBinding and ClusterRole/ClusterRoleBinding objects using the Kubernetes API to give access to our Azure Active Directory user and groups.

In order to do that, we need to connect to the cluster. You can get an administrator Kubernetes configuration file using the Azure CLI:

<pre name="f892" id="f892" class="graf graf--pre graf-after--p">$
az aks get-credentials -n CLUSTER_NAME -g RESOURCE_GROUP_NAME — admin</pre>

<pre name="488d" id="488d" class="graf graf--pre graf-after--pre">$
az aks get-credentials -n k8s-pre-prod -g kafka-pre-prod-rg — admin</pre>

<pre name="5b3d" id="5b3d" class="graf graf--pre graf-after--pre">$
k get nodes</pre>

The repository contains a simple ClusterRoleBinding object definition file cluster-admin-rolebinding.yaml that will make sure that the Azure Active Directory user ak@cloudssky.com can get cluster-admin role:

<pre name="e81d" id="e81d" class="graf graf--pre graf-after--p">$
kubectl apply -f cluster-admin-rolebinding.yaml</pre>

You can also create RoleBinding/ClusterRoleBinding for Azure Active Directory group, as described [here](https://docs.microsoft.com/en-us/azure/aks/aad-integration#create-rbac-binding).

### Connect to the cluster using RBAC and Azure AD

Once all your RBAC objects are defined in Kubernetes, you can get a Kubernetes configuration file that is not admin-enabled using the az aks get-credentials command without the — admin flag.

<pre name="3db5" id="3db5" class="graf graf--pre graf-after--p">$
az aks get credentials -n CLUSTER_NAME -g RESOURCE_GROUP_NAME</pre>

When you are going to use kubectl you are going to be asked to use the Azure Device Login authentication first:

<pre name="035b" id="035b" class="graf graf--pre graf-after--p">$
kubectl get nodes</pre>

To sign in, use a web browser to open the page [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and enter the code XXXXXXXX to authenticate.

### Deploy the next AKS dev-test cluster

Create a new resource group:

<pre name="6d3f" id="6d3f" class="graf graf--pre graf-after--p">$
az group create --name aceme-dev-test-rg --location westeurope</pre>

Initialize terraform with a new terraform state backend aceme-dev-test.tfstate:

<pre name="e468" id="e468" class="graf graf--pre graf-after--p">$
terraform init -backend-config=”storage_account_name=acemesa” -backend-config=”container_name=tfstate” -backend-config=”key=aceme-dev-test.tfstate”</pre>

Run the new plan and save it:

<pre name="1ca2" id="1ca2" class="graf graf--pre graf-after--p">$
terraform plan -var resource_group_name=aceme-dev-test-rg -var aks_name=aceme-kafka-dev-test -out aceme-kafka-dev-test-plan</pre>

Deploy the dev-test cluster:

<pre name="98cd" id="98cd" class="graf graf--pre graf-after--p">$
terraform apply aceme-kafka-dev-test-plan -auto-approve</pre>

**Rancher HA Deployment on AKS**

Please refer to this [deployment guide](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/) to install Rancher Management Server on your AKS Cluster.

**Rancher AAD Integration:**

Please refer to this documentation for AAD integration:

[https://rancher.com/docs/rancher/v2.x/en/admin-settings/authentication/azure-ad/](https://rancher.com/docs/rancher/v2.x/en/admin-settings/authentication/azure-ad/)

Get the Application Secret from key vault:

<pre name="9c8e" id="9c8e" class="graf graf--pre graf-after--p">$
az keyvault secret show --name rancher-aad-secret --vault-name aceme-aks-key-vault --query value -o tsv</pre>

Provide the following variables from your azure account in Rancher AAD integration interface:

<pre name="2e09" id="2e09" class="graf graf--pre graf-after--p">Tenant ID: xyz</pre>

<pre name="c611" id="c611" class="graf graf--pre graf-after--pre">Application ID: xyz</pre>

<pre name="470e" id="470e" class="graf graf--pre graf-after--pre">Endpoint: [https://login.microsoftonline.com/](https://login.microsoftonline.com/)</pre>

<pre name="49d7" id="49d7" class="graf graf--pre graf-after--pre">Graph Endpoint: [https://graph.windows.net/](https://graph.windows.net/)</pre>

<pre name="806b" id="806b" class="graf graf--pre graf-after--pre">Token Endpoint: [https://login.microsoftonline.com/xyz/oauth2/token](https://login.microsoftonline.com/xyz/oauth2/token)</pre>

<pre name="a1c7" id="a1c7" class="graf graf--pre graf-after--pre">Auth Endpoint: [https://login.microsoftonline.com/xyz/oauth2/authorize](https://login.microsoftonline.com/xyz/oauth2/authorize)</pre>

### Import AKS Clusters into Rancher Management Server

In Rancher click add cluster and select IMPORT:

![](https://cdn-images-1.medium.com/max/1600/0*LvSYCG7PGxphLAsx)

Provide a cluster name, e.g. aceme-kafka-pre-prod:

![](https://cdn-images-1.medium.com/max/1600/0*KeQ1fSCRmuV0bTXs)

Click create, Rancher provides the commands needed to import the AKS cluster, you can find the cluster user with:

<pre name="7b51" id="7b51" class="graf graf--pre graf-after--p">$
terraform output kube_config | grep clusterUser</pre>

<pre name="901b" id="901b" class="graf graf--pre graf-after--pre">$
    kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user <provide the user from command above></pre>

<pre name="9c85" id="9c85" class="graf graf--pre graf-after--pre">$
curl --insecure -sfL [https://aceme-rancher-ingress.westeurope.cloudapp.azure.com/v3/import/xyz.yaml](https://aceme-rancher-ingress.westeurope.cloudapp.azure.com/v3/import/xyz.yaml) | kubectl apply -f -</pre>

Your Rancher Cluster Management Server should look similar to this:

![](https://cdn-images-1.medium.com/max/1600/0*eBBFFVoAlSzmi8Da)

### Destroy the cluster

To destroy the cluster you shall run terraform destroy, please provide the right resource group name and aks cluster name:

<pre name="c235" id="c235" class="graf graf--pre graf-after--p">$
terraform destroy -var resource_group_name=aceme-kafka-pre-prod-rg -var aks_name=kafka-pre-prod</pre>

### Gotchas and TroubleShooting

**Problem:**
In Rancher if you call an AKS cluster, you’ll be faced with a Gotcha like this:

![](https://cdn-images-1.medium.com/max/1600/0*I384UgRDOBhkF7d6)

This is a known problem related to AKS, since kubectl get componentstatus delivers the wrong status of controller manager and scheduler:

<pre name="f0f3" id="f0f3" class="graf graf--pre graf-after--p">$
kubectl get componentstatus</pre>

<pre name="2dfd" id="2dfd" class="graf graf--pre graf-after--pre">NAME STATUS MESSAGE ERROR</pre>

<pre name="de67" id="de67" class="graf graf--pre graf-after--pre">controller-manager Unhealthy Get [http://127.0.0.1:10252/healthz:](http://127.0.0.1:10252/healthz:) dial tcp 127.0.0.1:10252: connect: connection refused</pre>

<pre name="6043" id="6043" class="graf graf--pre graf-after--pre">scheduler Unhealthy Get [http://127.0.0.1:10251/healthz:](http://127.0.0.1:10251/healthz:) dial tcp 127.0.0.1:10251: connect: connection refused</pre>

**Solution:**
Ignore it for now, it doesn’t hurt so much, this is a [known issue](https://github.com/Azure/AKS/issues/173).

### Delete the cattle-system namespace

**Problem:** In few cases after importing an AKS cluster and removing the cluster again through the Rancher interface, the clean up procedure doesn’t work as desired and the cattle-system namespace keeps in terminating state.

**Solution:**
Run kubectl edit namespace cattle-system and remove the finalizer called controller.cattle.io/namespace-auth, then save. Kubernetes won’t delete an object that has a finalizer on it.

Reference:
[https://github.com/rancher/rancher/issues/14715](https://github.com/rancher/rancher/issues/14715)

<pre name="49e6" id="49e6" class="graf graf--pre graf-after--p">$
cat delete-cattle-system-ns</pre>

<pre name="b1bf" id="b1bf" class="graf graf--pre graf-after--pre">NAMESPACE=cattle-system</pre>

<pre name="65b9" id="65b9" class="graf graf--pre graf-after--pre">kubectl proxy &</pre>

<pre name="3d84" id="3d84" class="graf graf--pre graf-after--pre">kubectl get namespace $NAMESPACE -o json |jq ‘.spec = {“finalizers”:[]}’ >temp.json</pre>

<pre name="4ee9" id="4ee9" class="graf graf--pre graf-after--pre">curl -k -H “Content-Type: application/json” -X PUT — data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize</pre>

### Observations

From time to time for few minutes the AKS clusters imported into Rancher are shown in pending state and I couldn’t find anything suspicious in the logs. Well, as long the k8s clusters are reachable and our workloads work, I think it doesn’t hurt so much.

### Conclusion

AKS is a free service and very young, Microsoft strives to attain at least 99.5% availability for the Kubernetes API server through their [SLA](https://azure.microsoft.com/en-us/support/legal/sla/kubernetes-service/v1_0/). But the nice thing is, we have the freedom of choice and can run K8s clusters with RKE on Azure as well and do real IaC with Terraform and extend beyond ARM, stay tuned.

### Related links and references:

**How Terraform works, an introduction**

[**Terraform — Some Introduction!**
_There are many tools available for the configuration management in the software industry. Ansible, chef, puppet, salt…_medium.com](https://medium.com/@prasannashasthri/terraform-some-introduction-a140bf81aa52 "https://medium.com/@prasannashasthri/terraform-some-introduction-a140bf81aa52")[](https://medium.com/@prasannashasthri/terraform-some-introduction-a140bf81aa52)

### Terraform — The definitive guide for Azure enthusiasts

[https://thorsten-hans.com/terraform-the-definitive-guide-for-azure-enthusiasts](https://thorsten-hans.com/terraform-the-definitive-guide-for-azure-enthusiasts)

**Terraform Azure Kubernetes Service cluster script by HashiCorp** [https://github.com/hashicorp/vault-guides/tree/master/identity/vault-agent-k8s-demo/terraform-azure](https://github.com/hashicorp/vault-guides/tree/master/identity/vault-agent-k8s-demo/terraform-azure)

**Protect the access key via key vault**

[https://docs.microsoft.com/en-us/azure/terraform/terraform-backend](https://docs.microsoft.com/en-us/azure/terraform/terraform-backend)

**Secure an Azure Kubernetes cluster with Azure Active Directory and RBAC**

[https://github.com/jcorioland/aks-rbac-azure-ad](https://github.com/jcorioland/aks-rbac-azure-ad)

**Azure Kubernetes Service (AKS) with Terraform**

[https://github.com/anubhavmishra/terraform-azurerm-aks](https://github.com/anubhavmishra/terraform-azurerm-aks)

**How to: Use Terraform to deploy Azure Kubernetes Service in Custom VNET with Kubenet**

[https://blog.jcorioland.io/archives/2019/03/13/azure-aks-custom-vnet-kubenet-terraform.html](https://blog.jcorioland.io/archives/2019/03/13/azure-aks-custom-vnet-kubenet-terraform.html)

**Using Terraform to extend beyond ARM**
[https://azurecitadel.com/automation/terraform/lab8/](https://azurecitadel.com/automation/terraform/lab8/)

**Terraform and multi tenant environment**
[https://azurecitadel.com/automation/terraform/lab5/](https://azurecitadel.com/automation/terraform/lab5/)

**Creating Azure Kubernetes Service (AKS) the Right Way**

[https://medium.com/@kari.marttila/creating-azure-kubernetes-service-aks-the-right-way-9b18c665a6fa](https://medium.com/@kari.marttila/creating-azure-kubernetes-service-aks-the-right-way-9b18c665a6fa)

**DEPLOY RANCHER ON AZURE FOR KUBERNETES MANAGEMENT**

[http://www.buchatech.com/2019/03/deploy-rancher-on-azure-for-kubernetes-management/](http://www.buchatech.com/2019/03/deploy-rancher-on-azure-for-kubernetes-management/)