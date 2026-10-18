#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../envs/dev"

terraform apply -auto-approve
aws eks update-kubeconfig --region us-east-1 --name jungle-fury-dev-eks
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# ArgoCD
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.5/manifests/install.yaml
kubectl -n argocd scale deploy argocd-dex-server --replicas=0
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-applicationset-controller --timeout=300s

# Metrics server for HPA
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml

# NGINX Ingress Controller                                                       ← ADD Day 5
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.service.type=LoadBalancer

# Prometheus + Grafana                                                           ← ADD Day 6
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword="JungleFury@2026" \
  --set prometheus.prometheusSpec.retention="7d" \
  --set alertmanager.enabled=false \
  --set grafana.persistence.enabled=false

# Hand app to GitOps
kubectl apply -n argocd -f ../../k8s/argocd/application.yaml

# Apply ingress and monitoring manifests                                         ← ADD
kubectl apply -f ../../k8s/ingress/ingress.yaml
kubectl apply -f ../../k8s/monitoring/servicemonitor.yaml

kubectl -n argocd get applications

echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

echo "Grafana: kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80"
echo "App URL: kubectl get svc -n ingress-nginx"