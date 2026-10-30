#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGION=ap-south-1
CLUSTER=skill-job-matcher-eks

cd "$ROOT/infra"
terraform init -input=false -backend-config=backend.hcl
terraform apply -input=false -auto-approve

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" >/dev/null
kubectl wait --for=condition=Ready nodes --all --timeout=300s

SECRET_ARN="$(terraform output -raw rds_secret_arn)"
aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text \
  | python3 -c 'import sys,json; sys.stdout.write(json.load(sys.stdin)["password"])' \
  | kubectl create secret generic db-credentials --from-file=DB_PASSWORD=/dev/stdin --dry-run=client -o yaml \
  | kubectl apply -f -
kubectl create configmap db-init --from-file=init.sql="$ROOT/db/init.sql" --dry-run=client -o yaml | kubectl apply -f -

echo "up done. Ab pipeline chalao (git push ya Actions mein Run workflow)."
