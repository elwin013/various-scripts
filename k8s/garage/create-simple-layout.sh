#!/usr/bin/env bash
#
# Simple script to create base layout for garage (s3-compatible object storage, https://garagehq.deuxfleurs.fr/) on k8s
# To be used with official helm charts
# 
# Assumes that nodes are autodiscovered and every node can have the same weight.
#
# Usage ./create-simple-layout.sh namespace
#
NAMESPACE=$1

if [ -z "$NAMESPACE" ]
then
      echo "Namespace not provided"
      exit
fi

PODS=`kubectl get pods -n $NAMESPACE --no-headers | cut -d' ' -f1`

while IFS= read -r POD_NAME; do
  NODE_ID=`kubectl exec -q -n $NAMESPACE $POD_NAME -c garage -- ./garage node id 2>/dev/null | head -n 1`
  kubectl exec  -n $NAMESPACE $POD_NAME -c garage -- ./garage layout assign $NODE_ID -z $POD_NAME -c 10 -t $POD_NAME
done <<< "$PODS"

SOME_POD=`echo $PODS | cut -d' ' -f1`

LAYOUT=`kubectl exec -n $NAMESPACE $SOME_POD -c garage -- ./garage layout show`

echo "$LAYOUT"

VERSION_TO_APPLY=`echo "$LAYOUT" | grep 'garage layout apply --version' | rev |  cut -d' ' -f1 | rev`

if [ -z "$VERSION_TO_APPLY" ]
then
      echo "No changes to apply"
      exit
fi
kubectl exec -n $NAMESPACE $SOME_POD -- ./garage layout apply --version $VERSION_TO_APPLY
