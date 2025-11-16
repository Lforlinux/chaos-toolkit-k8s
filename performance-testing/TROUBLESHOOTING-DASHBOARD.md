# Troubleshooting: Grafana Dashboard Shows No Data

## Problem
Grafana dashboard is loading but showing no data/metrics.

## Root Cause Analysis

### ✅ What's Working:
1. **statsd-exporter** is deployed and running
2. **Prometheus** is scraping statsd-exporter (verified via Prometheus API)
3. **Grafana** is connected to Prometheus

### ❌ What's Missing:
1. **No k6 metrics in Prometheus** - `statsd_exporter_lines_total = 0`
2. **Tests were run BEFORE statsd output was configured**
   - Previous tests: `k6-smoke-test` (54m ago), `k6-load-test` (71m ago)
   - These tests didn't have `--out statsd=...` configured
   - Need to run NEW tests with statsd output enabled

## Solution

### Step 1: Run a New Test
```bash
cd performance-testing
./deployment/run-test.sh smoke
```

This will:
- Run a test with statsd output configured
- Send metrics to statsd-exporter in real-time
- Make metrics available in Prometheus

### Step 2: Verify Metrics are Being Received

**Check statsd-exporter metrics:**
```bash
kubectl exec -n performance-testing $(kubectl get pods -n performance-testing -l app=statsd-exporter -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:9102/metrics | grep -i k6
```

**Check Prometheus:**
```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Query for k6 metrics
curl 'http://localhost:9090/api/v1/query?query={__name__=~"statsd_k6_.*"}'
```

### Step 3: Check Metric Names

Statsd-exporter converts k6 metrics with prefix `statsd_k6_`. Common metrics:
- `statsd_k6_http_reqs_total` - Total HTTP requests
- `statsd_k6_http_req_duration_seconds` - Request duration (histogram)
- `statsd_k6_http_req_failed_total` - Failed requests
- `statsd_k6_vus` - Virtual users

### Step 4: Verify Dashboard Queries

The dashboard uses these queries:
- `rate(statsd_k6_http_reqs_total[1m])` - Request rate
- `histogram_quantile(0.95, rate(statsd_k6_http_req_duration_seconds_bucket[1m]))` - p95 duration

**Test queries in Prometheus:**
1. Go to Prometheus UI: `http://localhost:9090`
2. Try query: `{__name__=~"statsd_k6_.*"}`
3. If no results, metrics haven't been sent yet

## Common Issues

### Issue 1: No Metrics After Running Test
**Check:**
```bash
# Check if test job has statsd output
kubectl get job k6-smoke-test -n performance-testing -o yaml | grep statsd

# Check test logs for statsd connection errors
kubectl logs -n performance-testing job/k6-smoke-test | grep -i statsd
```

**Fix:** Ensure job manifest has:
```yaml
args:
  - "--out"
  - "statsd=udp://statsd-exporter.performance-testing.svc.cluster.local:9125"
```

### Issue 2: Prometheus Not Scraping statsd-exporter
**Check:**
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Go to http://localhost:9090/targets
# Look for statsd-exporter target
```

**Fix:** Ensure statsd-exporter has annotations:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "9102"
```

### Issue 3: Wrong Metric Names in Dashboard
**Check actual metric names:**
```bash
kubectl exec -n performance-testing $(kubectl get pods -n performance-testing -l app=statsd-exporter -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:9102/metrics | grep k6
```

**Update dashboard queries** if metric names differ.

## Quick Test

Run this to verify end-to-end:
```bash
# 1. Run a quick smoke test
cd performance-testing
./deployment/run-test.sh smoke

# 2. While test is running, check metrics
kubectl exec -n performance-testing $(kubectl get pods -n performance-testing -l app=statsd-exporter -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:9102/metrics | grep k6

# 3. Check Prometheus (after test completes)
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090
# Query: {__name__=~"statsd_k6_.*"}
```

## Expected Result

After running a new test, you should see:
- Metrics in statsd-exporter: `/metrics` endpoint shows `statsd_k6_*` metrics
- Metrics in Prometheus: Query `{__name__=~"statsd_k6_.*"}` returns results
- Dashboard shows data: Graphs populate with test metrics

## Next Steps

1. ✅ Run a new test: `./deployment/run-test.sh smoke`
2. ✅ Verify metrics appear in Prometheus
3. ✅ Check dashboard updates in Grafana
4. ✅ If still no data, check metric names match dashboard queries

