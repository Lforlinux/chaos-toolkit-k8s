# Availability Test Application

This application provides real-time availability testing for the microservices demo, specifically testing the cart service functionality.

## Features

- **Automated Testing**: Runs every 5 minutes to test cart service functionality
- **Real User Simulation**: Tests adding and removing products from cart (actual user workflow)
- **Jenkins-like Dashboard**: Shows test results with green/red status indicators
- **SRE Monitoring**: Provides uptime percentage and consecutive failure tracking
- **Manual Testing**: Ability to trigger tests on-demand
- **ALB Integration**: Exposed via Application Load Balancer for external access

## Test Case

The application performs a comprehensive cart service test:

1. **Frontend Accessibility**: Verifies the frontend service is reachable
2. **Add to Cart**: Simulates adding a product to the cart
3. **Remove from Cart**: Simulates removing the product from the cart
4. **Health Check**: Verifies cart service health endpoints

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   ALB/Ingress   │────│ Availability Test│────│ Cart Service    │
│                 │    │    Application   │    │ (default ns)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   ArgoCD App     │
                       │ (GitOps Deploy)  │
                       └──────────────────┘
```

## Configuration

### Environment Variables

- `CART_SERVICE_URL`: URL of the cart service (default: `http://cartservice:7070`)
- `FRONTEND_URL`: URL of the frontend service (default: `http://frontend:8080`)
- `TEST_INTERVAL`: Test execution interval in seconds (default: `300` = 5 minutes)

### Kubernetes Resources

- **Namespace**: `availability-test`
- **Deployment**: 2 replicas for high availability
- **Service**: ClusterIP service for internal communication
- **LoadBalancer**: External access via AWS ELB
- **Ingress**: ALB configuration for custom domain

## Deployment

### Via ArgoCD (Recommended)

The application is automatically deployed via ArgoCD GitOps:

```bash
kubectl apply -f argocd/availability-test-app.yaml
```

### Manual Deployment

```bash
# Create namespace
kubectl apply -f availability-test/namespace.yaml

# Deploy application
kubectl apply -f availability-test/deployment.yaml

# Expose via LoadBalancer
kubectl apply -f availability-test/loadbalancer.yaml
```

## Access

### LoadBalancer URL

After deployment, get the external URL:

```bash
kubectl get svc availability-test-loadbalancer -n availability-test
```

### Dashboard Features

- **Status Overview**: Overall system health, uptime percentage, test results
- **Test Details**: Individual test execution details and error messages
- **Manual Testing**: Run tests on-demand
- **Real-time Updates**: Auto-refresh every 30 seconds

## Monitoring

### Health Endpoints

- `/api/health`: Application health check
- `/api/status`: Current test status and results
- `/api/run-test`: Manually trigger test execution

### Metrics

- **Uptime Percentage**: Calculated based on test success rate
- **Consecutive Failures**: Tracks continuous failures for alerting
- **Test Duration**: Performance monitoring
- **Success Rate**: Pass/fail ratio over time

## SRE Integration

### Alerting Criteria

- **Red Status**: Consecutive failures > 0
- **Green Status**: All tests passing
- **Uptime < 95%**: Service degradation threshold

### Dashboard Indicators

- **Green**: All systems operational
- **Red**: Service issues detected
- **Yellow**: Initializing or unknown state

## Troubleshooting

### Common Issues

1. **Cart Service Unreachable**: Check if cartservice is running in default namespace
2. **Frontend Issues**: Verify frontend service accessibility
3. **Test Failures**: Check application logs for detailed error messages

### Logs

```bash
kubectl logs -f deployment/availability-test-app -n availability-test
```

### Debug Mode

Set environment variable for detailed logging:

```yaml
env:
- name: FLASK_DEBUG
  value: "true"
```

## Customization

### Adding New Tests

1. Add new test methods to `AvailabilityTester` class
2. Update the test suite in `run_availability_test()`
3. Modify the dashboard template to display new test results

### Changing Test Interval

Update the `TEST_INTERVAL` environment variable in the deployment:

```yaml
env:
- name: TEST_INTERVAL
  value: "600"  # 10 minutes
```

## Security

- Non-root container execution
- Resource limits and requests
- Health checks for reliability
- CORS enabled for web access
