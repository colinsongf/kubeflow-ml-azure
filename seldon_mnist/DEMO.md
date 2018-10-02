# Model serving Seldon-core

Install minikube locally [here](https://github.com/kubernetes/minikube) 

_macOS_
```bash
brew cask install minikube
```

Start minikube
```bash
➜  ~ minikube start

There is a newer version of minikube available (v0.29.0).  Download it here:
https://github.com/kubernetes/minikube/releases/tag/v0.29.0

To disable this notification, run the following:
minikube config set WantUpdateNotification false
Starting local Kubernetes v1.10.0 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.
```

# Seldon-core 

We will install seldon-core standalone via helm, for other install alternative please see [here](https://github.com/SeldonIO/seldon-core/blob/master/docs/install.md)


Following the installation from helm [quickstart](https://docs.helm.sh/using_helm/#quickstart)

```bash
helm init
```

update to latest repository
```bash
helm repo update  
```

```bash
helm install seldon-core-crd --name seldon-core-crd --repo https://storage.googleapis.com/seldon-charts \
     --set usage_metrics.enabled=false
 ```
 
```bash
helm install seldon-core --name seldon-core --repo https://storage.googleapis.com/seldon-charts \
     --set apife.enabled=true \
     --set rbac.enabled=false \
     --set ambassador.enabled=false 
```


seldon analytics grafana 

```bash
Install seldon prediciton analytics
```bash
helm install seldon-core-analytics --name seldon-core-analytics --set rbac.enabled=false \
--set grafana_prom_admin_password=password --set persistence.enabled=false \
--repo https://storage.googleapis.com/seldon-charts
```

# Build train image

go to **train** folder and build the docker image

```bash
docker build -t mnist_sk_boost_learn:0.3 .
```

run the image and mount the current folder to **/data**

```bash
docker run -p 5000:5000 --mount type=bind,src=$(pwd),dst=/data mnist_sk_boost_learn:0.3
``` 

create the local Persistent volume and claim if you are running locally.

```bash
kubectl create -f k8s/local-pv.yaml
kubectl create -f k8s/local-pvc.yaml
```

### Proxy for rest service
```python
kubectl port-forward $(kubectl get pods -n kubeflow -l app=seldon-apiserver-container-app -o jsonpath='{.items[0].metadata.name}') -n kubeflow 8002:8080
```


### Rest call in python

 ```python
from seldon_utils import *
API_GATEWAY_REST="localhost:8002"
for i in range(20): rest_request_api_gateway("oauth-key","oauth-secret",API_GATEWAY_REST, data_size=784)
```

