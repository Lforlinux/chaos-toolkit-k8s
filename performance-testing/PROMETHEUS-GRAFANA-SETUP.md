# k6 Performance Testing - Prometheus & Grafana Integration

This guide explains how k6 test results are exported to Prometheus and visualized in Grafana.

## Architecture

```
k6 Test Jobs → experimental-prometheus-rw → Prometheus (direct write) → Grafana (visualizes)
```

## Components

### 1. k6 Test Jobs
- All test jobs (smoke, load, stress, spike) output metrics via Prometheus remote write
- Uses `experimental-prometheus-rw` output (supported in k6 v0.55.0+)
- Metrics are sent in real-time during test execution directly to Prometheus
- Metrics include:
  - HTTP request rate
  - HTTP request duration (p50, p95, p99)
  - HTTP request failures
  - Virtual users (VUs)
  - Data transferred

### 2. Prometheus
- **Remote Write Receiver**: Enabled with `--web.enable-remote-write-receiver` flag
- **Endpoint**: `http://prometheus.monitoring.svc.cluster.local:9090/api/v1/write`
- **Metrics**: All k6 metrics are available in Prometheus with prefix `k6_*`

### 4. Grafana Dashboard
- **Official k6 Dashboard**: Dashboard ID `19665` (recommended)
  - Go to Grafana → Dashboards → Import
  - Enter dashboard ID: `19665`
  - Select Prometheus as data source
  - This is the official k6 Prometheus dashboard from Grafana Labs
- **Custom Dashboard**: `dashboards/k6-performance-testing-dashboard.json` (optional)
  - Alternative custom dashboard if you need specific visualizations

## Setup Instructions

### 1. Enable Prometheus Remote Write Receiver
Prometheus remote write receiver is enabled in `monitoring/prometheus-enhanced.yaml` with the flag:
```
--web.enable-remote-write-receiver
```

This is deployed via ArgoCD (monitoring-stack app) or manually:
```bash
kubectl apply -f monitoring/prometheus-enhanced.yaml
# Restart Prometheus pod to apply the new flag
kubectl rollout restart deployment/prometheus -n monitoring
```

### 2. Verify Prometheus Remote Write Receiver
```bash
# Check Prometheus is running with remote write receiver enabled
kubectl get pods -n monitoring -l app=prometheus

# Check Prometheus targets
# Access Prometheus UI and check Targets page
# Should see statsd-exporter in the targets list
```

### 3. Run a Test
```bash
# Run any test - metrics will be sent to Prometheus in real-time
./deployment/run-test.sh smoke
./deployment/run-test.sh load
```

### 4. Import Grafana Dashboard

**Option 1: Official k6 Dashboard (Recommended)**
1. Access Grafana UI
2. Go to Dashboards → Import
3. Enter Dashboard ID: `19665`
4. Select Prometheus as the data source
5. Click Import

**Option 2: Custom Dashboard**
1. Access Grafana UI
2. Go to Dashboards → Import
3. Upload `dashboards/k6-performance-testing-dashboard.json`
4. Select Prometheus as the data source
5. Save the dashboard

## Available Metrics

All k6 metrics are prefixed with `k6_` in Prometheus:

- `k6_http_reqs_total` - Total HTTP requests
- `k6_http_req_duration_seconds` - HTTP request duration (histogram)
- `k6_http_req_failed_total` - Failed HTTP requests
- `k6_vus` - Current virtual users
- `k6_data_received_total` - Data received
- `k6_data_sent_total` - Data sent
- `k6_iterations_total` - Total iterations

## Querying Metrics in Prometheus

### Example Queries

```promql
# Request rate (requests per second)
rate(k6_http_reqs_total[1m])

# 95th percentile response time
histogram_quantile(0.95, rate(k6_http_req_duration_seconds_bucket[1m]))

# Error rate percentage
rate(k6_http_req_failed_total[5m]) / rate(k6_http_reqs_total[5m]) * 100

# Current virtual users
k6_vus

# Filter by test type
rate(k6_http_reqs_total[1m]){test_type="load"}
```

## Troubleshooting

### Metrics not appearing in Prometheus

1. **Check Prometheus remote write receiver is enabled**:
   ```bash
   kubectl get deployment prometheus -n monitoring -o yaml | grep remote-write-receiver
   # Should see: --web.enable-remote-write-receiver
   ```

2. **Check Prometheus logs**:
   ```bash
   kubectl logs -n monitoring -l app=prometheus | grep -i "remote.*write"
   ```

3. **Verify Prometheus is receiving metrics**:
   - Access Prometheus UI
   - Query: `{__name__=~"k6_.*"}`
   - Should see k6 metrics if tests are running

4. **Check k6 job logs**:
   ```bash
   kubectl logs -n performance-testing job/k6-smoke-test
   # Look for prometheus-rw connection errors
   ```

5. **Test Prometheus remote write endpoint**:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   curl -X POST http://localhost:9090/api/v1/write
   # Should return 204 No Content (endpoint exists)
   ```

### Dashboard not showing data

1. **Verify Prometheus data source** is configured in Grafana
2. **Check time range** - ensure it covers when tests were run
3. **Verify metric names** - check if metrics exist in Prometheus:
   ```promql
   {__name__=~"k6_.*"}
   ```

## Notes

- Metrics are sent in real-time during test execution via HTTP POST
- Metrics persist in Prometheus based on retention settings (default: 30 days)
- Each test type (smoke, load, stress, spike) is labeled with `test_type` label
- Uses Prometheus remote write protocol (HTTP-based, reliable)
- Requires Prometheus v2.33.0+ (remote write receiver feature)

