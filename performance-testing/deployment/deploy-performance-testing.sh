#!/bin/bash

# Deploy k6 Performance Testing Infrastructure
# This script deploys all necessary resources for k6 performance testing
# Run from repository root: ./performance-testing/deploy-performance-testing.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERFORMANCE_TESTING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PERFORMANCE_TESTING_DIR"

echo "🚀 Deploying k6 Performance Testing Infrastructure..."

# Apply namespace
echo "📦 Creating namespace..."
kubectl apply -f k8s-manifest/namespace.yaml

# Apply ConfigMap with test scripts
echo "📝 Creating ConfigMap with test scripts..."
kubectl apply -f k8s-manifest/configmap.yaml

# Apply CronJob for scheduled tests
echo "⏰ Creating scheduled test CronJob..."
kubectl apply -f k8s-manifest/cronjob-scheduled-test.yaml

echo "✅ k6 Performance Testing infrastructure deployed successfully!"
echo ""
echo "📋 Available resources:"
kubectl get all -n performance-testing
echo ""
echo "🧪 To run tests:"
echo "   ./deployment/run-test.sh smoke"
echo "   ./deployment/run-test.sh load"
echo "   ./deployment/run-test.sh stress"
echo "   ./deployment/run-test.sh spike"
echo ""
echo "📊 To view scheduled test jobs:"
echo "   kubectl get cronjobs -n performance-testing"
echo "   kubectl get jobs -n performance-testing"

