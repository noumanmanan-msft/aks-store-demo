#!/bin/bash
alias k=kubectl
alias kga='kubectl get all'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kge='kubectl get events'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdn='kubectl describe node'
alias kde='kubectl describe event'
alias kctx='kubectl config use-context'
alias kcfg='kubectl config get-contexts'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
alias kapply='kubectl apply -f'
alias kdelete='kubectl delete -f'

# Refer to the following url to get full description of the commands on how to scale AKS cluster using KEDA and Karpenter
# https://github.com/Azure-Samples/aks-labs/blob/main/docs/operations/scaling-with-keda-and-karpenter.md

RG_NAME="rg-aks-karpenter-demo-eastus2-001"
CLUSTER_NAME="aks-karpenter-demo-eastus2-001"
LOCATION="eastus2"

az group create -n $RG_NAME -l $LOCATION

# Create the AKS cluster with KEDA and NAP enabled
# This operation will take several minutes
az aks create \
--name $CLUSTER_NAME \
--resource-group $RG_NAME \
--enable-keda \
--node-provisioning-mode Auto \
--network-plugin azure \
--network-plugin-mode overlay \
--network-dataplane cilium \
--generate-ssh-keys

# Or update an existing cluster to enable KEDA and NAP
az aks update --name $CLUSTER_NAME --resource-group $RG_NAME --node-provisioning-mode Auto

# Now let's get the cluster access credentials
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME

# Set your subscription ID
SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
az account set -s $SUBSCRIPTION_ID

# Confirm you've selected the right subscription
az account show -o table


# Create the pet store namespace
kubectl create ns pets

# Deploy the pet store components to the pets namespace
kubectl apply -f https://raw.githubusercontent.com/Azure-Samples/aks-store-demo/main/aks-store-all-in-one.yaml -n pets

# Check the deployment status
kubectl get all -n pets


# Get the store URL
echo "Pet Store URL: http://$(kubectl get svc store-front -n pets -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

# Increase the virtual customer replica count
kubectl scale deployment virtual-customer -n pets --replicas=4

# You can keep an eye on the deployment with either of the following commands
kubectl get deployment,pods -n pets
kubectl get deploy -n pets -w

# port-forward to the rabbitmq http endpoint
kubectl port-forward svc/rabbitmq -n pets 15672:15672

# curl the rabbitmq http endpoint and filter the output with jq
curl -u username:password http://localhost:15672/api/queues/%2f/orders|jq '.backing_queue_status.len'

# First make sure your environment variables are still set
# RG_NAME=rg-demo-eastus2-001
# CLUSTER_NAME=aks-multi-tenant-eastus2-001

# Get the default nodepool name. It should be nodepool1, but we'll confirm
DEFAULT_NODEPOOL_NAME=$(az aks nodepool list -g $RG_NAME --cluster-name $CLUSTER_NAME --query '[0].name' -o tsv)

# Now apply the CriticalAddonsOnly taint to the default nodepool
az aks nodepool update \
-g $RG_NAME \
--cluster-name $CLUSTER_NAME \
-n $DEFAULT_NODEPOOL_NAME \
--node-taints CriticalAddonsOnly=true:NoExecute

# Watch the events raised by karpenter
kubectl get events -A --field-selector source=karpenter -w

# watch the new node start and pods get scheduled
watch kubectl get nodes,pods -n pets -o wide


# Now apply the new arm nodepool profile and watch the shift
kubectl apply -f arm-nodepool-profile.yaml 

# Apply the new profile with the new NodeClass
kubectl apply -f arm-nodepool-profile_v2.yaml

# Have a look at the NodePool definitions that ship with the NAP managed add-on
kubectl get nodepool
kubectl describe nodepool default

# Notice how the 'system-surge' nodepool uses the 'kubernetes.azure.com/mode' label to focus on system nodes.
kubectl describe nodepool system-surge
