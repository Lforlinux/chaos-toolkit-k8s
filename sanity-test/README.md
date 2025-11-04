# Sanity Test Application

## Overview

The Sanity Test application performs health checks on all microservices in the `online-boutique` namespace. It runs automatically every minute and provides a dashboard showing the health status of each service.

## Features

- ✅ **Automated Health Checks**: Checks health endpoints of all microservices
- ✅ **Real-time Dashboard**: Web UI showing test results
- ✅ **Periodic Testing**: Runs every 60 seconds automatically
- ✅ **Individual Service Status**: Shows pass/fail for each microservice
- ✅ **Response Time Metrics**: Displays response time for each health check
- ✅ **History**: Keeps last 50 test runs

## Microservices Tested

- adservice
- cartservice
- checkoutservice
- currencyservice
- emailservice
- frontend
- paymentservice (gRPC)
- productcatalogservice
- recommendationservice
- shippingservice (gRPC)
- redis-cart

## Access

### LoadBalancer URL
After deployment, access via:
```
http://<loadbalancer-external-ip>
```

### Port Forward
```bash
kubectl port-forward -n sanity-test svc/sanity-test-service 8080:80
```
Then access: http://localhost:8080

## API Endpoints

- `GET /` - Dashboard UI
- `GET /api/status` - Get test status and results
- `GET /api/run-test` - Trigger manual test run
- `GET /api/health` - Health check endpoint

## Configuration

Environment variables:
- `NAMESPACE`: Target namespace (default: `online-boutique`)
- `TEST_INTERVAL`: Test interval in seconds (default: `60`)
- `TIMEOUT`: Request timeout in seconds (default: `5`)

## Deployment

Deployed via ArgoCD:
```bash
kubectl apply -f argocd/sanity-test-app.yaml
```

## Test Results

Each test run shows:
- Overall status (passed/failed)
- Individual service status
- Response times
- Error messages (if any)
- Timestamp

A test **passes** if all services return healthy status.
A test **fails** if any service is unhealthy or unreachable.

