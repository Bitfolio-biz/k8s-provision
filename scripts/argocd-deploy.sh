#!/usr/bin/env bash

GKE_NAME=focused-world-310920-gke
GKE_REGION=us-east4
ARGOCD_VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

# Get credentials
gcloud container clusters get-credentials $GKE_NAME --region $GKE_REGION

echo "Deploying Argo CD version: $ARGOCD_VERSION"
kubectl create namespace argocd
kubectl apply -n argocd -f install.yaml
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl wait --for=condition=Ready pod -n argocd -l app.kubernetes.io/name=argocd-server

echo "Downloading Argo CD CLI version: $ARGOCD_VERSION"
sudo curl -sSL --create-dirs -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

echo 'Waiting for IP address allocation'
sleep 45

echo "Configuring Argo CD with cluster: $GKE_NAME"
PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# Argo CD 1.8 and earlier
#PWD=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')
HOST=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].*}')
argocd login $HOST --insecure --username admin --password $PWD
CONTEXT_NAME=$(kubectl config get-contexts -o name)
argocd cluster add $CONTEXT_NAME

echo ''
echo '----------------'
echo "ArgoCD UI: $(kubectl get svc -n argocd argocd-server -o jsonpath='http://{.status.loadBalancer.ingress[0].*}')"
echo "ArgoCD Pod name: $(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')"
echo '----------------'

echo ''
echo "Change the password:"
echo $PWD
echo "argocd account update-password"
echo "Delete the secret argocd-initial-admin-secret"
echo ''
