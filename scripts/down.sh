#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../envs/dev"

# Guard: stop if this isn't your account
[ "$(aws sts get-caller-identity --query Account --output text)" = "762682890391" ] \
  || { echo "Wrong AWS account"; exit 1; }

# 1. Delete anything in Kubernetes that owns AWS resources (load balancers)
kubectl -n argocd delete applications --all --ignore-not-found --timeout=60s || true
kubectl delete ingress --all -A --ignore-not-found --timeout=60s || true
for ns in lab monitoring ingress-nginx app argocd; do
  kubectl delete namespace "$ns" --ignore-not-found --timeout=180s || true
done

# 2. Wait until AWS has really removed the load balancers (they block VPC deletion)
echo "Waiting for load balancers to disappear..."
for i in $(seq 1 30); do
  v2=$(aws elbv2 describe-load-balancers --query "length(LoadBalancers)" --output text 2>/dev/null || echo 0)
  v1=$(aws elb describe-load-balancers --query "length(LoadBalancerDescriptions)" --output text 2>/dev/null || echo 0)
  if [ "$v2" = "0" ] && [ "$v1" = "0" ]; then echo "No load balancers left."; break; fi
  echo "  still present (elbv2=$v2, classic=$v1), checking again in 10s..."
  sleep 10
done

# 3. Expensive things first
terraform destroy -auto-approve \
  -target=module.compute \
  -target=module.database \
  -target=module.vpc.aws_nat_gateway.main \
  -target=module.vpc.aws_eip.nat

# 4. Everything else
terraform destroy -auto-approve

# 5. Verify with AWS itself, not just Terraform state
echo "--- EKS clusters (expect none) ---"
aws eks list-clusters --region us-east-1
echo "--- Active NAT gateways (expect none) ---"
aws ec2 describe-nat-gateways --region us-east-1 \
  --filter Name=state,Values=available,pending \
  --query "NatGateways[].NatGatewayId"
echo "--- Load balancers (expect none) ---"
aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerArn" --output text

echo "All resources destroyed."