### Deploy kubeflow into a kubernetes cluster with terraform

# Helm install client
`
brew install kubernetes-helm
`

or download the appropriate binary from https://github.com/helm/helm/releases
and place it on your PATH.


# Helm install in kubernetes
Create tiller service account and give it cluster admin role
```
$ kubectl create -f rbac-config.yaml
serviceaccount/tiller created
clusterrolebinding.rbac.authorization.k8s.io/tiller created
```
```
$ helm init --service-account tiller

```

Advanced details https://docs.helm.sh/using_helm/#role-based-access-control

# Create kubeflow name space
```
kubectl create -f kubeflow-namespace.yaml
```

# kubeflow as default context

```bash
kubectl config set-context kubeflow --namespace=kubeflow
```


# Install kubeflow with ksonnet
Install ksonnet by e.g. downloading binary from https://github.com/ksonnet/ksonnet/releases
and place it in the PATH.

Init kubeflow. You might have to ensure that equinor proxy env is activated before doing this.
```
ks init kubeflow
cd kubeflow
```


Add registry with latest tag verion
`
ks registry add kubeflow https://github.com/kubeflow/kubeflow/tree/v0.2.5/kubeflow
`

Check that the registry has been added successfully 
```bash
ks registry describe kubeflow

REGISTRY NAME:
kubeflow

URI:
https://github.com/kubeflow/kubeflow/tree/v0.2.5/kubeflow

PROTOCOL:
github

PACKAGES:
  argo
  automation
  core
  katib
  mpi-job
  new-package-stub
  openmpi
  pachyderm
  pytorch-job
  seldon
  tf-serving
```

Install components
```
ks pkg install kubeflow/core
ks pkg install kubeflow/argo
ks pkg install kubeflow/seldon
ks pkg install kubeflow/tf-serving
ks pkg install kubeflow/tf-job
```

If you get errors `403 API rate limit exceeded ` from github then create a personal access token and store
it as an enviornment variable, as described in https://github.com/ksonnet/ksonnet/blob/master/docs/troubleshooting.md#github-rate-limiting-errors

```
ks generate core kubeflow-core --name=kubeflow-core --namespace=kubeflow
```

Add enviroment dev
```bash
export NAMESPACE=kubeflow
ks env add dev --namespace=kubeflow
```
```bash
ks apply dev -c kubeflow-core
```

JupyterHub connection
get the pod name and create a port forward 
``bash

PODNAME=`kubectl get pods --namespace=${NAMESPACE} --selector="app=tf-hub" --output=template --template="{{with index .items 0}}{{.metadata.name}}{{end}}"`
kubectl port-forward --namespace=${NAMESPACE} $PODNAME 8000:8000
``
use any username and leave password blank (Ideally we add LDAP authentication to this)

# Storage Class
Make sure you have an storage account created in your azure resource group, see in terraform main `azurerm_storage_account`

Create storage class `kubectl apply -f azure-file-sc.yaml`


Create a cluster role and binding

```bash
kubectl create -f azure-pvc-roles.yaml
clusterrole.rbac.authorization.k8s.io/system:azure-cloud-provider created
clusterrolebinding.rbac.authorization.k8s.io/system:azure-cloud-provider created
```

Create a persistent volume claim

```bash
kubectl create -f azure-file-pvc.yaml

```

Create a PVC
```bash
kubectl create -f azure-file-pvc.yaml
persistentvolumeclaim/azurefile created
```

Check pvc created properly
```bash
kubectl get pvc azurefile
NAME        STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
azurefile   Bound     pvc-0323d7e6-bbf7-11e8-8d3a-fad93241fe5c   5Gi        RWX            azurefile      25m
```

User the persisten volume claim _azurefile_ share at _/mnt/azure_ path.

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: shell-demo
spec:
  containers:
    - name: myfrontend
      image: nginx
      volumeMounts:
      - mountPath: "/mnt/azure"
        name: volume
  volumes:
    - name: volume
      persistentVolumeClaim:
        claimName: azurefile
```


### Argo


Install Argo cli [here](https://github.com/argoproj/argo/blob/master/demo.md#1-download-argo)
```bash
brew install argoproj/tap/argo
```
KS generate core 
```bash
 ks generate argo kubeflow-argo --name=kubeflow-argo --namespace=kubeflow
```

Apply argo component to dev enviroment

```bash
ks apply dev -c kubeflow-argo
``` 

Connect to the argo-ui

```bash
PODNAME=`kubectl get pods --namespace=${NAMESPACE} --selector="app=argo-ui" --output=template --template="{{with index .items 0}}{{.metadata.name}}{{end}}"`
kubectl -n argo port-forward --namespace=${NAMESPACE} $PODNAME 8001:8001
```


# Cheat sheet

list all CRD
```bash 
kubectl api-resources --verbs=list
```
