#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

helm uninstall skill 2>/dev/null || echo "helm release skill nahi mila, aage barh raha hoon"
for i in $(seq 1 20); do
  [ -z "$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text)" ] && break
  sleep 15
done

cd "$ROOT/infra"
terraform destroy -input=false -auto-approve

echo "--- bacha hua (khali hona chahiye) ---"
aws eks list-clusters --query clusters --output text
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier' --output text
aws ec2 describe-nat-gateways --filter Name=state,Values=available,pending --query 'NatGateways[].NatGatewayId' --output text
aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text
aws ec2 describe-volumes --query 'Volumes[].VolumeId' --output text
aws ec2 describe-addresses --query 'Addresses[].PublicIp' --output text
