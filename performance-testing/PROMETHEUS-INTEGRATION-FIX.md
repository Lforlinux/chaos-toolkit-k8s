# Fixing Prometheus Integration for k6 v0.55.0+

## Problem
- k6 v0.55.0+ removed built-in `statsd` output
- `grafana/k6:v0.54.0` image doesn't exist (wrong tag format)
- Tests are running but metrics aren't reaching Prometheus

## Solution Options

### Option 1: Use Prometheus Remote Write (Recommended)
k6 supports `experimental-prometheus-rw` output that writes directly to Prometheus.

**Pros:**
- No custom image needed
- Direct integration with Prometheus
- Works with k6 latest

**Cons:**
- Requires Prometheus remote write receiver (Prometheus doesn't receive remote write by default)
- Need to set up a remote write receiver service

### Option 2: Use xk6-output-statsd Extension
Build a custom k6 image with the statsd extension.

**Pros:**
- Works with existing statsd-exporter setup
- No changes to Prometheus needed

**Cons:**
- Need to build and maintain custom Docker image
- More complex setup

### Option 3: Use Prometheus Pushgateway
Use Prometheus Pushgateway as an intermediary.

**Pros:**
- Simple setup
- Works with k6 latest

**Cons:**
- Additional component to maintain
- Not ideal for high-frequency metrics

## Recommended: Option 1 - Prometheus Remote Write

### Step 1: Create Prometheus Remote Write Receiver

We need a service that can receive remote write and forward to Prometheus, or configure Prometheus to accept remote write.

### Step 2: Update k6 Jobs

Add `experimental-prometheus-rw` output to k6 jobs:
```yaml
args:
  - "--out"
  - "experimental-prometheus-rw=http://prometheus-remote-write-receiver.monitoring.svc.cluster.local:9090/api/v1/write"
```

### Step 3: Verify Metrics in Prometheus

Check that metrics appear in Prometheus with prefix `k6_*`.

## Current Status

✅ Tests are running (JSON output only)
❌ Prometheus integration disabled (statsd removed)
📋 Next: Implement Prometheus remote write solution

