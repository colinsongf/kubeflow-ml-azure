# Kubeflow ML platform
This package is the collection of tested components to build Kubelfow DS platform

## Terraform
[terraform/README.MD]() to setup an AKS cluster cluster and ACR 

## Kubeflow
[kubeflow/README.MD]() to setup a kubeflow components via helm charts, you will find example using argo 
and AMES housing SeldonDeployment **machinelearning.seldon.io/v1alpha1**  for newer version see **seldon_mnist**

## Seldon-core
[seldon_mnist/DEMO.md]() we setup a standalone seldon-core and seldon-core analytics. 
We do best effort to make this running on minikube. 