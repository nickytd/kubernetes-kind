#!/bin/bash

set -eo pipefail

dir=$(dirname $0)

echo "setting up kind cluster"

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
kind create cluster --name kind --config ${dir}/kind-config.yaml

kubectl cluster-info --context kind-kind

IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane)
sudo ifconfig lo0 alias $IP

kind get nodes | xargs -I{} docker exec -t {} sysctl fs.inotify.max_user_instances=1500


for var in "$@"
do
    if [[ "$var" = "--with-ingress-controller" ]]; then
		echo "deploy nginx-ingress controler"
		kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
		kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=15m
	fi

	if [[ "$var" = "--add-net-alias" ]]; then
        IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane)
        sudo ifconfig lo0 alias $IP
    done
done