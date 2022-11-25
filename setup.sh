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

echo "check for kind cluster"
if [[ `kind get clusters` == "kind" ]]; then
    echo "kind cluster found"
else
    config="${dir}/kind-config.yaml"
    for var in "$@"
    do
      if [[ "$var" = "--calico" ]]; then
        echo "create kind cluster with calico CNI"
        config="${dir}/kind-config-calico.yaml"
      fi
    done
    echo "config: $config"
    kind create cluster --name kind --config $config
fi

kubectl cluster-info --context kind-kind

IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane)
sudo ifconfig lo0 alias $IP

kind get nodes | xargs -I{} docker exec -t {} sysctl fs.inotify.max_user_instances=1500


for var in "$@"
do
    if [[ "$var" = "--calico" ]]; then
        echo "deploy calico"
        $dir/../kubernetes-calico/setup.sh
    fi

    if [[ "$var" = "--ingress-controller" ]]; then
		echo "deploy nginx-ingress controler"
		kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
		kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=15m
	fi

	if [[ "$var" = "--add-net-alias" ]]; then
        IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane)
        sudo ifconfig lo0 alias $IP
    fi
done