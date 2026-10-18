#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../envs/dev"

[ "$(aws sts get-caller-identity --query Account --output text)" = "762682890391" ] || { echo "Wrong AWS account"; exit 1; }

# 1. Remove k8s workloads that own AWS resources
kubectl -n argocd delete applications --all --ignore-not-found || true
kubectl delete ingress --all -A --ignore-not-found || true
kubectl delete namespace monitoring --ignore-not-found --timeout=180s || true    # ← ADD Day 6
kubectl delete namespace ingress-nginx --ignore-not-found --timeout=180s || true # ← ADD Day 5
kubectl delete namespace app --ignore-not-found --timeout=180s || true
kubectl delete namespace argocd --ignore-not-found --timeout=180s || true

# 2. Wait for LBs to be released by AWS before destroying VPC
echo "Waiting 30s for AWS to release load balancers..."
sleep 30

# Verify no LBs remain
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[].LoadBalancerArn" --output text
aws elb describe-load-balancers \
  --query "LoadBalancerDescriptions[].LoadBalancerName" --output text

# 3. Destroy expensive resources first, then everything
terraform destroy -auto-approve \
  -target=module.compute \
  -target=module.database \
  -target=module.vpc.aws_nat_gateway.main \
  -target=module.vpc.aws_eip.nat

# 4. Destroy remaining resources
terraform destroy -auto-approve                                                  # ← ADD this

# 5. Verify
aws eks list-clusters --region us-east-1
aws ec2 describe-nat-gateways --region us-east-1 \
  --filter Name=state,Values=available,pending \
  --query "NatGateways[].NatGatewayId"

echo "All resources destroyed."