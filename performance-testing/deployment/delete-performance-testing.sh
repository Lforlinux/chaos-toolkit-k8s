#!/bin/bash

# Delete k6 Performance Testing Infrastructure
# Run from repository root: ./performance-testing/delete-performance-testing.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERFORMANCE_TESTING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PERFORMANCE_TESTING_DIR"

echo "🗑️  Deleting k6 Performance Testing Infrastructure..."

# Delete jobs
echo "🧹 Cleaning up jobs..."
kubectl delete jobs -n performance-testing -l app=k6-performance-test --ignore-not-found=true

# Delete cronjobs
echo "🧹 Cleaning up cronjobs..."
kubectl delete cronjobs -n performance-testing -l app=k6-performance-test --ignore-not-found=true

# Delete CronJob manifest
echo "🧹 Deleting CronJob..."
kubectl delete -f k8s-manifest/cronjob-scheduled-test.yaml --ignore-not-found=true

# Delete Job manifests
echo "🧹 Deleting Jobs..."
kubectl delete -f k8s-manifest/job-smoke-test.yaml --ignore-not-found=true
kubectl delete -f k8s-manifest/job-load-test.yaml --ignore-not-found=true
kubectl delete -f k8s-manifest/job-stress-test.yaml --ignore-not-found=true
kubectl delete -f k8s-manifest/job-spike-test.yaml --ignore-not-found=true

# Delete ConfigMap
echo "🧹 Deleting ConfigMap..."
kubectl delete -f k8s-manifest/configmap.yaml --ignore-not-found=true

# Delete namespace (this will delete everything)
echo "🧹 Deleting namespace..."
kubectl delete -f k8s-manifest/namespace.yaml --ignore-not-found=true

echo "✅ k6 Performance Testing infrastructure deleted successfully!"

