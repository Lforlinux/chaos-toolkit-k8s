# k6 Performance Testing for Online Boutique

This directory contains k6 performance testing infrastructure for the Online Boutique microservices application.

## 🚀 Quick Start

### Run Tests

Use the simple script to run any test type:

```bash
# Run smoke test (default)
./deployment/run-test.sh smoke

# Run load test
./deployment/run-test.sh load

# Run stress test
./deployment/run-test.sh stress

# Run spike test
./deployment/run-test.sh spike
```

The script will:
- Create the test job
- Show logs in real-time
- Display results when complete

## 📋 Test Types

### Smoke Test
- **Purpose**: Basic functionality verification
- **Duration**: ~4 minutes
- **Load**: 1 virtual user
- **Use Case**: Quick validation after deployment

### Load Test
- **Purpose**: Normal production load testing
- **Duration**: ~16 minutes
- **Load**: 50-100 virtual users
- **Use Case**: Validate performance under normal conditions

### Stress Test
- **Purpose**: Find breaking point and maximum capacity
- **Duration**: ~40 minutes
- **Load**: 100-500 virtual users
- **Use Case**: Capacity planning and limit identification

### Spike Test
- **Purpose**: Test handling of sudden traffic spikes
- **Duration**: ~6 minutes
- **Load**: 10 → 500 → 1000 users (sudden spikes)
- **Use Case**: Validate autoscaling and resilience

## 🎯 What Tests Validate

Each test includes:

### Frontend Tests (HTTP)
- Homepage accessibility
- Product page loading
- Frontend error tracking

### Backend Tests (via Health Check)
- Health check endpoint
- Backend service validation
- Backend error tracking

## 📊 Understanding Results

### Success Indicators
```
✓ frontend homepage status is 200
✓ backend health check status is 200
✓ checks: 100.00%
✓ thresholds: 100.00%
```

### Key Metrics
- **checks**: Test assertions (should be 100%)
- **thresholds**: Performance criteria (should pass)
- **http_req_duration**: Response times (p95, p99)
- **frontend_errors**: Frontend-specific errors
- **backend_errors**: Backend-specific errors
- **http_req_failed**: Failed request rate

## 🔧 Prerequisites

- Kubernetes cluster with kubectl configured
- Online Boutique application deployed
- `performance-testing` namespace exists

## 📦 Deployment

### Initial Setup

```bash
# Deploy performance testing infrastructure
./deployment/deploy-performance-testing.sh
```

This will:
- Create the `performance-testing` namespace
- Create ConfigMap with test scripts
- Set up CronJob for scheduled tests (optional)

## 🧪 Running Tests

### Using the Script (Recommended)

```bash
# Run any test type
./run-test.sh [smoke|load|stress|spike]
```

### Manual Execution

```bash
# Run smoke test
kubectl apply -f k8s-manifest/job-smoke-test.yaml
kubectl logs -f job/k6-smoke-test -n performance-testing

# Run load test
kubectl apply -f k8s-manifest/job-load-test.yaml
kubectl logs -f job/k6-load-test -n performance-testing

# Run stress test
kubectl apply -f k8s-manifest/job-stress-test.yaml
kubectl logs -f job/k6-stress-test -n performance-testing

# Run spike test
kubectl apply -f k8s-manifest/job-spike-test.yaml
kubectl logs -f job/k6-spike-test -n performance-testing
```

## 📊 Scheduled Tests

Automated smoke tests run every 6 hours:

```bash
# Deploy scheduled test
kubectl apply -f k8s-manifest/cronjob-scheduled-test.yaml

# View scheduled jobs
kubectl get cronjobs -n performance-testing

# View job history
kubectl get jobs -n performance-testing
```

## 🗑️ Cleanup

```bash
# Delete all resources
./deployment/delete-performance-testing.sh

# Or manually
kubectl delete -f k8s-manifest/ --ignore-not-found=true
```

## 📁 Directory Structure

```
performance-testing/
├── deployment/              # Deployment and management scripts
│   ├── run-test.sh         # Main script to run tests
│   ├── deploy-performance-testing.sh
│   ├── delete-performance-testing.sh
│   └── check-service-protocols.sh
├── k6-scripts/             # k6 test scripts
│   ├── k6-smoke-test.js
│   ├── k6-load-test.js
│   ├── k6-stress-test.js
│   └── k6-spike-test.js
├── k8s-manifest/           # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── job-smoke-test.yaml
│   ├── job-load-test.yaml
│   ├── job-stress-test.yaml
│   ├── job-spike-test.yaml
│   └── cronjob-scheduled-test.yaml
└── README.md
```

## 🔗 Integration with ArgoCD

This performance testing setup can be integrated with ArgoCD for GitOps deployment. See `argocd/apps/performance-testing-app.yaml` for the ArgoCD application definition.

---

**Happy Performance Testing!** 🚀
