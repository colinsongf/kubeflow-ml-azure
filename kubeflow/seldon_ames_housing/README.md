# Ames housing value predicition using XGBoost on kubeflow

Gives cluster-admin role to the default service account in the kubeflow namespace
kubectl create clusterrolebinding seldon-admin --clusterrole=cluster-admin --serviceaccount=kubeflow:default

Install seldon via ksonnet
```bash
 ks generate seldon kubeflow-seldon --name=kubeflow-seldon --namespace=kubeflow
```
Apply to dev environment 
```bash
ks apply dev -c kubeflow-seldon
``` 


this is adapted from [xgboost_ames_housing](https://github.com/kubeflow/examples/tree/master/xgboost_ames_housing) to run on Azure

Set name and version variables
```bash
IMAGE_NAME=ames-housing
VERSION=v1
```
Build docker image and push it to Azure container registry, make sure you are authenticated
```bash
az acr login --name ${CONTAINER_REGISTRY_NAME}
```

```bash
docker build -t azcore.azurecr.io/dev/${IMAGE_NAME}:${VERSION} .

docker push azcore.azurecr.io/dev/${IMAGE_NAME}:${VERSION}
```

Now we are ready to train our model

```bash
kubectl create -f py-pod.yaml
```

Check the pod status

```bash
kubectl logs xg-boost
....
[98]	validation_0-rmse:33094.2
[99]	validation_0-rmse:33000.1
[100]	validation_0-rmse:32989.6
[101]	validation_0-rmse:32978.8
[102]	validation_0-rmse:33054
[103]	validation_0-rmse:33050.2
Stopping. Best iteration:
[63]	validation_0-rmse:32862.5

Best RMSE on eval: 32862.49 with 64 rounds
MAE on test: 17986.57
Model export success /mnt/xgboost/housing.dat
```

Finally serving the model, via seldon-serve

Copy folder `seldon_serve` locally and run the seldon python wrapper
We will delete the housing.dat so that we make sure we are loading the trained model from PVC folder 

```bash
cd seldon_ames_housing
docker run -v $(pwd):/seldon_serve seldonio/core-python-wrapper:0.7 /seldon_serve HousingServe 0.1 azcore.azurecr.io --base-image=python:3.6 --image-name=dev/housingserve
```
The previous command will create a build folder build and push image to the registry
```bash
./build_image.sh
./push_image.sh
```

We are ready to create a SeldonDeployment CRD (Custom Resource Descriptor)

```bash
kubectl create -f serving_xgboost_model.json
seldondeployment.machinelearning.seldon.io/xgboost-ames created
```

Let's check that our SeldonDeployment is up and running
```bash
housingserve-housingserve-5d9448877d-vkc96   2/2       Running   0          3m
```

We check the pods logs and we see that the model serving is up and listening on 9000
```bash
 kubectl -n kubeflow logs housingserve-housingserve-5d9448877d-vkc96 -c housingserve
 * Running on http://0.0.0.0:9000/ (Press CTRL+C to quit)
 ```
 
 # Sample Request
 Lets send request to the model
 
 Seldon core uses ambassador to route its request
 
 ```bash
kubectl port-forward $(kubectl get pods -n kubeflow -l service=ambassador -o jsonpath='{.items[0].metadata.name}') -n kubeflow 8080:80
```
 
 
 xgboost-ames
 
 
 ```bash
 curl -H "Content-Type: application/json" \
 -d '{"data":{"tensor":{"shape":[1,37],"values":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37]}}}' \
 http://localhost:8080/seldon/xgboost-ames/api/v0.1/predictions
```

# Seldon Prediction Analytics

Install seldon prediciton analytics
```bash
helm install seldon-core-analytics --name seldon-core-analytics --set rbac.enabled=false \
--set grafana_prom_admin_password=password --set persistence.enabled=false \
--repo https://storage.googleapis.com/seldon-charts --namespace kubeflow
``` 

port forward then checkout the dashboard [here](http://localhost:3000/dashboard/db/prediction-analytics?refresh=1m&orgId=1)
```bash
kubectl port-forward $(kubectl get pods -n kubeflow -l app=grafana-prom-server -o jsonpath='{.items[0].metadata.name}') -n kubeflow 3000:3000
```

# Seldon core with multiples models deployment

Install tf-job operator
```bash
ks generate tf-job-operator tf-job-operator --name=tf-job-operator --namespace=kubeflow
ks apply default -c tf-job-operator
```

 # Update to Seldon-core
 
 With the kubeflow registry, we have installed seldon-core version 1.6.0 where the latest version on the time of writing is v0.2.3
 Let's add the seldon-core registry
 
 Install via ksonnet
 
```bash
ks registry add seldon-core https://github.com/SeldonIO/seldon-core/tree/v0.2.3/seldon-core
```

```bash
ks pkg install seldon-core/seldon-core
```

```bash
ks generate seldon-core seldon-core \
   --withApife=false \
   --withAmbassador=true \
   --withRbac=true 
```

```bash
ks apply dev -c seldon-core -n kubeflow
```


# Install via helm
Current v0.2.3 there is a bug with ksonnet deployment hence we are re-installing this with helm

```bash
helm install seldon-core-crd --name seldon-core-crd --repo https://storage.googleapis.com/seldon-charts --set rbac.enabled=false \
     --set usage_metrics.enabled=false --namespace kubeflow
```

```bash
helm install seldon-core --name seldon-core --repo https://storage.googleapis.com/seldon-charts \
     --namespace kubeflow \
     --set apife.enabled=true \
     --set rbac.enabled=false \
     --set ambassador.enabled=false 
```