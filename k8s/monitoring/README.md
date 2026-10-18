# Monitoring Stack

Installed via Helm using kube-prometheus-stack.

## Install command
```bash
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword="<your-password>" \
  --set prometheus.prometheusSpec.retention="7d" \
  --set alertmanager.enabled=false \
  --set grafana.persistence.enabled=false
```

## Access Grafana
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```
Open: http://localhost:3000 (admin / your-password)

## Key dashboards
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Pod  
- Kubernetes / Nodes
