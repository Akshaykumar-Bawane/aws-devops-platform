#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../envs/dev"

# Retry helper: network calls (GitHub, Helm repos) time out sometimes
retry() {
  local n=1 max=4
  until "$@"; do
    if (( n >= max )); then echo "FAILED after $max attempts: $*"; return 1; fi
    echo "Attempt $n failed, retrying in 10s..."; n=$((n+1)); sleep 10
  done
}

# 1. Infrastructure
terraform apply -auto-approve
aws eks update-kubeconfig --region us-east-1 --name jungle-fury-dev-eks
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# 2. Helm repos
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
retry helm repo update

# 3. Namespaces (created up front so nothing races)
for ns in argocd app lab; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

# 4. ArgoCD (pinned version, server-side apply avoids the "Too long" CRD error)
retry kubectl apply --server-side --force-conflicts -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.5/manifests/install.yaml
kubectl -n argocd scale deploy argocd-dex-server --replicas=0
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-applicationset-controller --timeout=300s

# 5. metrics-server (HPA needs it)
retry kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml

# 6. NGINX Ingress (--wait so its admission webhook is ready before we apply Ingress rules)
retry helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.service.type=LoadBalancer \
  --wait --timeout 5m

# 7. Prometheus + Grafana
retry helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword="JungleFury@2026" \
  --set prometheus.prometheusSpec.retention="7d" \
  --set alertmanager.enabled=false \
  --set grafana.persistence.enabled=false

# 8. Hand the app to GitOps, then ingress and monitoring manifests
kubectl apply -n argocd -f ../../k8s/argocd/application.yaml
retry kubectl apply -f ../../k8s/ingress/ingress.yaml
retry kubectl apply -f ../../k8s/monitoring/servicemonitor.yaml

kubectl -n argocd get applications

echo
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
echo
echo "Grafana : kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80"
echo "ArgoCD  : kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "App URL : kubectl get svc -n ingress-nginx"
echo
echo "REMINDER: ECR was recreated EMPTY. Run the CI workflow once (Actions -> Run workflow)"
echo "          or the app pods will stay in ImagePullBackOff."