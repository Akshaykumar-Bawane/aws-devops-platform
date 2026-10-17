#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../envs/dev"

terraform apply -auto-approve
aws eks update-kubeconfig --region us-east-1 --name jungle-fury-dev-eks
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Argo CD: pinned version, server-side apply (avoids the "Too long" CRD error)
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.5/manifests/install.yaml
kubectl -n argocd scale deploy argocd-dex-server --replicas=0
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-applicationset-controller --timeout=300s

# metrics-server so the HPA works and the app goes Healthy
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml

# Hand the app over to GitOps
kubectl apply -n argocd -f ../../k8s/argocd/application.yaml
kubectl -n argocd get applications

echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
