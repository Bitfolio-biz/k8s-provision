#!/usr/bin/env bash

if [[ -f "/usr/local/bin/helm" ]]; then
  echo "helm is installed"
else
  return 1
fi
echo "See https://github.com/influxdata/helm-charts/tree/master/charts/influxdb"
echo "See https://github.com/influxdata/helm-charts/blob/master/charts/influxdb/values.yaml"
echo ''
echo "Adding influxdata helm repo"
helm repo add influxdata https://helm.influxdata.com/
helm repo update

cat <<EOF > influx-values.yaml

persistence:
  enabled: true
  accessMode: ReadWriteOnce
  size: 32Gi
EOF

echo "Install with: "
echo "kubectl create namespace monitoring"
echo "helm upgrade --install mon-influxdb -n monitoring -f influx-values.yaml influxdata/influxdb"
echo ''
