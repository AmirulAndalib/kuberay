#!/bin/bash

set -x
set errexit

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# DIR is the absolute directory of this script (`install.sh`)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)"

# Install the kube-prometheus-stack v48.2.1 helm chart with `overrides.yaml` file.
# https://github.com/prometheus-community/helm-charts/tree/kube-prometheus-stack-48.2.1/charts/kube-prometheus-stack
kubectl create namespace prometheus-system
kubectl create configmap grafana-dashboards --from-file="$DIR/../../config/grafana/" --dry-run=client -o yaml | sed -e '/^metadata:/ a\
  namespace: prometheus-system\
  labels:\
    grafana_dashboard: "1"' | kubectl create -f -

helm --namespace prometheus-system install prometheus prometheus-community/kube-prometheus-stack --version 48.2.1 -f "${DIR}"/overrides.yaml

# set the place of monitor files
monitor_dir="${DIR}"/../../config/prometheus

# start to install monitor
pushd "${monitor_dir}"
for file in *
do
kubectl apply -f "${file}"
done
popd
