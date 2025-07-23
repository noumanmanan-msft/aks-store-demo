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

RG_NAME="rg-demo-eastus2-001"
CLUSTER_NAME="aks-multi-tenant-eastus2-001"
LOCATION="eastus2"

# Set your subscription ID
SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
az account set -s $SUBSCRIPTION_ID

# Confirm you've selected the right subscription
az account show -o table

