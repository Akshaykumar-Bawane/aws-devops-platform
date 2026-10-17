#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../envs/dev"

# Guard: stop if this isn't your account
[ "$(aws sts get-caller-identity --query Account --output text)" = "762682890391" ] || { echo "Wrong AWS account"; exit 1; }

# 1. Remove anything that owns AWS resources outside Terraform (LBs, volumes)
kubectl -n argocd delete applications --all --ignore-not-found || true
kubectl delete ingress --all -A --ignore-not-found || true
kubectl delete namespace app --ignore-not-found --timeout=180s || true
kubectl delete namespace argocd --ignore-not-found --timeout=180s || true
# (add: kubectl delete namespace ingress-nginx --ignore-not-found, once you install it on Day 5)

# 2. Make sure no load balancers are left (they block VPC deletion)
aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerArn" --output text
aws elb describe-load-balancers --query "LoadBalancerDescriptions[].LoadBalancerName" --output text
# Both should print nothing. If not, wait a minute and re-check before continuing.

# 3. Expensive things first, then the rest
terraform destroy -auto-approve \
  -target=module.compute \
  -target=module.jenkins \
  -target=module.database \
  -target=module.vpc.aws_nat_gateway.main \
  -target=module.vpc.aws_eip.nat

# 4. Verify with AWS, not just state
aws eks list-clusters --region us-east-1
aws ec2 describe-nat-gateways --region us-east-1 \
  --filter Name=state,Values=available,pending --query "NatGateways[].NatGatewayId"
