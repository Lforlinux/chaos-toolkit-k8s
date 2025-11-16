#!/bin/bash

# k6 Performance Test Runner
# Usage: ./run-test.sh [smoke|load|stress|spike|help]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERFORMANCE_TESTING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PERFORMANCE_TESTING_DIR"

NAMESPACE="performance-testing"
TEST_TYPE=${1:-}

# Show help if no argument provided or help requested
if [ -z "$TEST_TYPE" ] || [ "$TEST_TYPE" = "help" ] || [ "$TEST_TYPE" = "-h" ] || [ "$TEST_TYPE" = "--help" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  k6 Performance Test Runner"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Usage: $0 [test-type]"
  echo ""
  echo "Available Test Types:"
  echo ""
  echo "  smoke   - Basic functionality test"
  echo "           • Duration: ~4 minutes"
  echo "           • Load: 1 virtual user"
  echo "           • Purpose: Verify basic app functionality"
  echo ""
  echo "  load    - Normal production load test"
  echo "           • Duration: ~16 minutes"
  echo "           • Load: 50-100 virtual users"
  echo "           • Purpose: Test under expected production load"
  echo ""
  echo "  stress  - Find application breaking point"
  echo "           • Duration: ~40 minutes"
  echo "           • Load: 100-500 virtual users (gradual increase)"
  echo "           • Purpose: Discover maximum capacity and limits"
  echo ""
  echo "  spike   - Sudden traffic spike test"
  echo "           • Duration: ~6 minutes"
  echo "           • Load: 10 → 500 → 1000 virtual users (sudden spikes)"
  echo "           • Purpose: Test handling of sudden traffic surges"
  echo ""
  echo "Examples:"
  echo "  $0 smoke      # Run smoke test"
  echo "  $0 load       # Run load test"
  echo "  $0 stress     # Run stress test"
  echo "  $0 spike      # Run spike test"
  echo ""
  echo "What Each Test Does:"
  echo "  • Tests frontend (HTTP endpoints: homepage, product pages)"
  echo "  • Tests backend (via health check endpoint)"
  echo "  • Monitors response times, error rates, and thresholds"
  echo ""
  echo "View Results:"
  echo "  kubectl logs job/k6-<test-type>-test -n performance-testing"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Validate test type
case $TEST_TYPE in
  smoke|load|stress|spike)
    ;;
  *)
    echo "❌ Invalid test type: $TEST_TYPE"
    echo ""
    echo "Usage: $0 [smoke|load|stress|spike]"
    echo ""
    echo "Run '$0 help' for detailed information about each test type."
    exit 1
    ;;
esac

JOB_NAME="k6-${TEST_TYPE}-test"
JOB_FILE="k8s-manifest/job-${TEST_TYPE}-test.yaml"

# Check if job file exists
if [ ! -f "$JOB_FILE" ]; then
    echo "❌ Job file not found: $JOB_FILE"
    exit 1
fi

echo "🚀 Running k6 $TEST_TYPE test..."
echo ""

# Delete existing job if it exists
kubectl delete job $JOB_NAME -n $NAMESPACE --ignore-not-found=true > /dev/null 2>&1

# Apply job
echo "📦 Creating test job..."
kubectl apply -f $JOB_FILE

# Wait for job to start
echo "⏳ Waiting for job to start..."
sleep 3

# Get pod name
POD_NAME=$(kubectl get pods -n $NAMESPACE -l job-name=$JOB_NAME -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$POD_NAME" ]; then
    echo "⚠️  Pod not found yet, waiting..."
    sleep 5
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l job-name=$JOB_NAME -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
fi

if [ -z "$POD_NAME" ]; then
    echo "❌ Could not find pod for job $JOB_NAME"
    echo "Check job status: kubectl get job $JOB_NAME -n $NAMESPACE"
    exit 1
fi

echo "✅ Job started: $JOB_NAME"
echo "📊 Pod: $POD_NAME"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Follow logs
kubectl logs -f job/$JOB_NAME -n $NAMESPACE

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Test completed!"
echo ""
echo "To view results again:"
echo "  kubectl logs job/$JOB_NAME -n $NAMESPACE"
echo ""
echo "To check job status:"
echo "  kubectl get job $JOB_NAME -n $NAMESPACE"

