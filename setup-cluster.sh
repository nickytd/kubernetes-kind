#!/bin/bash

set -eo pipefail

dir=$(dirname $0)

echo "setting up cluster"

if ! command -v kind &> /dev/null
then
    echo "get kind https://kind.sigs.k8s.io"
    exit
fi

if ! command -v kubectl &> /dev/null
then
    echo "get kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl/"
    exit
fi

echo "create cluster"
kind create cluster --name kind --config ${dir}/cluster/kind-config.yaml

kubectl cluster-info --context kind-kind

for var in "$@"
do
    if [[ "$var" = "--with-ingress-controller" ]]; then
		echo "deploy nginx-ingress controler"
		kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
		kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=15m
	fi
done		