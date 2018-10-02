# kubeflow-ml-azure

Deployment script for data analytics platform based on Terraform. 

# Prerequisites

Azure command line installed and user authenticated

Terraform installed

# Setup

Create an Azure Service principal RBAC user with Contributor role 
```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/your_subscription_id"
```
output
```
Retrying role assignment creation: 1/36
Retrying role assignment creation: 2/36
{
  "appId": "your_client_id_from_script_execution",
  "displayName": "azure-cli-2018-09-16-10-56-26",
  "name": "http://azure-cli-2018-09-16-10-56-26",
  "password": "your_client_secret_from_script_execution",
  "tenant": "your_tenant_id_from_script_execution"
}
```

For azure authentication you will need to create a file terraform.tfvars which will contain the following 

```
azure_subscription_id = "your_subscription_id_from_script_execution"
azure_client_id       = "your_client_id_from_script_execution"
azure_client_secret   = "your_client_secret_from_script_execution"
azure_tenant_id       = "your_tenant_id_from_script_execution"
```
Run
`terraform init`
to download the azure terraform provider


Run 
`terraform plan -out run.plan`

you should see that terraform is planing to create two new resources

```
  + azurerm_kubernetes_cluster.k8s
  + azurerm_resource_group.k8s
.....
Plan: 2 to add, 0 to change, 0 to destroy.
```

Now we are ready to execute terraform plan

```
terraform apply "run.plan"
```

This take few minutes to complete...

Let's check that our cluster is up and running (Terraform output variable will contains the raw configuration of the newly created Kubernetes cluster)

```
echo "$(terraform output kube_config)" > ~/.kube/kubeflow

export KUBECONFIG=~/.kube/kubeflow

➜  thd-platform git:(master) ✗ kubectl get nodes
NAME                     STATUS    ROLES     AGE       VERSION
aks-default-38504768-0   Ready     agent     5m        v1.9.9
aks-default-38504768-1   Ready     agent     5m        v1.9.9
aks-default-38504768-2   Ready     agent     5m        v1.9.9

```


setup proxy 
```
az aks browse --resource-group dcoe_rg --name kubeflow
#OR
kubectl proxy
```

Open Kubernetes dashboard

```
open 'http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default'
```


## Azure Container Registry

### Individual login with Azure AD

```bash
az acr login --name azcore
```

