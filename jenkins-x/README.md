# Jenkins-x deployment on Azure

Get jenkins-x [here](https://jenkins-x.io/getting-started/install/)

Resource group `jenkins_rg`

Storage account `jenkinsstorageac` 

Virtual network `jenkins_rg-vnet`

```bash
jx create cluster aks --cluster-name jenkins --default-admin-password admin \
    --location "North Europe" --nodes 3 \
    --resource-group-name jenkins_rg --username you@email.com

```    