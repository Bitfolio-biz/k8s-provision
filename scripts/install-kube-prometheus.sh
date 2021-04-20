#!/usr/bin/env bash

if [[ -f "/usr/local/bin/helm" ]]; then
  echo "helm is installed"
else
  return 1
fi

echo "Adding prometheus-community helm repo"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

cat <<EOF > prometheus-values.yaml
coreDns:
  enabled: false

kubeDns:
  enabled: true

prometheusOperator:
  createCustomResource: false

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

grafana:
  service:
    type: LoadBalancer
    annotations:
      cloud.google.com/load-balancer-type: "External"
  persistence:
    enabled: true
    accessModes: ["ReadWriteOnce"]
    size: 50Gi
EOF

echo "Install with: "
echo "kubectl create namespace monitoring"
echo "helm install grafana-prometheus -n monitoring -f prometheus-values.yaml prometheus-community/kube-prometheus-stack "
echo ''
